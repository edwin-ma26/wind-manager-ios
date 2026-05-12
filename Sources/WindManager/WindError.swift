import Foundation

/// Errors that can occur during a Wind Connect flow.
public enum WindError: Error, LocalizedError {
    /// The user cancelled the Wind Connect sheet.
    case cancelled
    /// The user denied the connection request.
    case denied
    /// A valid callback URL was not received.
    case missingCallback
    /// The Wind Connect URL could not be constructed.
    case invalidURL
    /// `balance()` was called but no Wind user ID is stored.
    case notConnected
    /// The balance endpoint returned a non-200 response.
    case balanceFetchFailed
    /// An underlying `ASWebAuthenticationSession` error.
    case sessionError(Error)
    /// An unexpected error with a description.
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .cancelled:           return "Wind Connect was cancelled."
        case .denied:              return "The user denied the Wind wallet connection."
        case .missingCallback:     return "Wind Connect did not return a valid result."
        case .invalidURL:          return "Could not construct the Wind Connect URL."
        case .notConnected:        return "No Wind wallet is connected."
        case .balanceFetchFailed:  return "Could not fetch the wallet balance."
        case .sessionError(let e): return e.localizedDescription
        case .unknown(let msg):    return "Wind error: \(msg)"
        }
    }
}
