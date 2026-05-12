import Foundation
import AuthenticationServices

/// The main entry point for the Wind SDK.
///
/// ```swift
/// let wind = WindManager(appId: "YOUR_APP_ID", appName: "Your App")
///
/// // async/await
/// let result = try await wind.connect(from: self, callbackScheme: "myapp")
/// print(result.windUserId)
///
/// // Completion handler
/// wind.connect(from: self, callbackScheme: "myapp") { result in
///     switch result {
///     case .success(let connected): print(connected.windUserId)
///     case .failure(let error):    print(error)
///     }
/// }
/// ```
@MainActor
public final class WindManager: NSObject {

    // MARK: - Configuration

    public let appId: String
    public let appName: String
    private let windBaseURL: String
    private let keychain: WindKeychain

    public init(
        appId: String,
        appName: String,
        windBaseURL: String = "https://wind-user.vercel.app",
        keychainService: String = "wind-manager"
    ) {
        self.appId = appId
        self.appName = appName
        self.windBaseURL = windBaseURL
        self.keychain = WindKeychain(service: keychainService)
    }

    // MARK: - Connection state

    /// The stored Wind user ID, or `nil` if not connected.
    public func getStoredUserId() -> String? {
        keychain.read(account: "wind_user_id")
    }

    /// `true` if a Wind user ID is stored in the Keychain.
    public func isConnected() -> Bool {
        getStoredUserId() != nil
    }

    /// Removes the stored Wind user ID from the Keychain.
    public func disconnect() {
        keychain.delete(account: "wind_user_id")
    }

    // MARK: - Connect (async/await)

    /// Opens Wind Connect using `ASWebAuthenticationSession` and returns the result.
    ///
    /// - Parameters:
    ///   - viewController: The presenting view controller.
    ///   - callbackScheme: Your app's URL scheme registered in Info.plist, e.g. `"myapp"`.
    ///   - externalUserId: Optional — your app's user ID, stored server-side as the pairing key.
    ///   - forceAuth: Pass `true` to clear the Wind session and force a fresh login.
    /// - Returns: A `WindConnectResult` containing `windUserId`, `windEmail`, and optional `balanceCents`.
    /// - Throws: `WindError`
    public func connect(
        from viewController: UIViewController,
        callbackScheme: String,
        externalUserId: String? = nil,
        forceAuth: Bool = false
    ) async throws -> WindConnectResult {
        try await withCheckedThrowingContinuation { continuation in
            connect(
                from: viewController,
                callbackScheme: callbackScheme,
                externalUserId: externalUserId,
                forceAuth: forceAuth
            ) { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - Connect (completion handler)

    /// Completion-handler version of `connect`. Prefer the `async` overload in new code.
    public func connect(
        from viewController: UIViewController,
        callbackScheme: String,
        externalUserId: String? = nil,
        forceAuth: Bool = false,
        completion: @escaping (Result<WindConnectResult, WindError>) -> Void
    ) {
        guard let connectURL = buildConnectURL(
            callbackScheme: callbackScheme,
            externalUserId: externalUserId,
            forceAuth: forceAuth
        ) else {
            completion(.failure(.invalidURL))
            return
        }

        let session = ASWebAuthenticationSession(
            url: connectURL,
            callbackURLScheme: callbackScheme
        ) { [weak self] callbackURL, error in
            guard let self else { return }

            if let error {
                let nsError = error as NSError
                if nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    completion(.failure(.cancelled))
                } else {
                    completion(.failure(.sessionError(error)))
                }
                return
            }

            guard let callbackURL else {
                completion(.failure(.missingCallback))
                return
            }

            switch self.parseCallback(callbackURL) {
            case .success(let result):
                self.keychain.write(result.windUserId, account: "wind_user_id")
                completion(.success(result))
            case .failure(let err):
                completion(.failure(err))
            }
        }

        session.presentationContextProvider = viewController
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }

    // MARK: - Balance

    /// Fetches the user's current wallet balance from your backend.
    ///
    /// Your backend endpoint should accept `?userId=<windUserId>` and return
    /// `{ "balanceCents": 1234 }`. This keeps your Wind API key server-side.
    ///
    /// ```swift
    /// let cents = try await wind.balance(from: URL(string: "https://api.yourapp.com/balance")!)
    /// label.text = String(format: "$%.2f", Double(cents) / 100)
    /// ```
    ///
    /// - Parameter backendURL: Your backend endpoint URL (without query params).
    /// - Returns: The spendable balance in cents.
    public func balance(from backendURL: URL) async throws -> Int {
        guard let windUserId = getStoredUserId() else {
            throw WindError.notConnected
        }

        var components = URLComponents(url: backendURL, resolvingAgainstBaseURL: false)
        var items = components?.queryItems ?? []
        items.append(URLQueryItem(name: "userId", value: windUserId))
        components?.queryItems = items

        guard let url = components?.url else {
            throw WindError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WindError.balanceFetchFailed
        }

        struct BalanceResponse: Decodable { let balanceCents: Int }
        let decoded = try JSONDecoder().decode(BalanceResponse.self, from: data)
        return decoded.balanceCents
    }

    // MARK: - Private helpers

    private func buildConnectURL(
        callbackScheme: String,
        externalUserId: String?,
        forceAuth: Bool
    ) -> URL? {
        var components = URLComponents(string: "\(windBaseURL)/wind/connect")
        var items: [URLQueryItem] = [
            .init(name: "mode",       value: "link"),
            .init(name: "app_id",     value: appId),
            .init(name: "app_name",   value: appName),
            .init(name: "return_url", value: "\(callbackScheme)://wind-callback"),
        ]
        if let externalUserId {
            items.append(.init(name: "external_user_id", value: externalUserId))
        }
        if forceAuth {
            items.append(.init(name: "force_auth", value: "true"))
        }
        components?.queryItems = items
        return components?.url
    }

    private func parseCallback(_ url: URL) -> Result<WindConnectResult, WindError> {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let params = Dictionary(
            uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        if let error = params["error"] {
            return .failure(error == "denied" ? .denied : .unknown(error))
        }

        guard params["connected"] == "true",
              let windUserId = params["wind_user_id"], !windUserId.isEmpty
        else {
            return .failure(.missingCallback)
        }

        return .success(WindConnectResult(
            windUserId:   windUserId,
            windEmail:    params["wind_email"],
            balanceCents: params["balance_cents"].flatMap(Int.init)
        ))
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension UIViewController: @retroactive ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window ?? ASPresentationAnchor()
    }
}
