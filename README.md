# WindManager — iOS SDK for Wind

Swift package that connects an iOS app to **Wind**, usage-based payments infrastructure for consumer AI apps. The SDK handles the connect flow and stores the resulting Wind user ID in the Keychain, so your app can bill AI usage to a user's Wind wallet without holding provider keys.

## Usage

```swift
import WindManager

let wind = WindManager(appId: "YOUR_APP_ID", appName: "Your App")

// async/await
let result = try await wind.connect(from: viewController, callbackScheme: "myapp")
print(result.windUserId)

// or completion handler
wind.connect(from: viewController, callbackScheme: "myapp") { result in
    switch result {
    case .success(let connected): print(connected.windUserId)
    case .failure(let error):     print(error)
    }
}

wind.isConnected()       // Bool
wind.getStoredUserId()   // String?
wind.disconnect()
```

## Install

Swift Package Manager: add this repository URL in Xcode, or in `Package.swift`:

```swift
.package(url: "https://github.com/edwin-ma26/wind-manager-ios", from: "0.1.0")
```

## What's inside

- `WindManager.swift` — `@MainActor` entry point; opens the Wind connect page in an `ASWebAuthenticationSession` and parses the callback.
- `WindKeychain.swift` — minimal Keychain wrapper for the user ID.
- `WindConnectResult.swift`, `WindResponse.swift`, `WindError.swift` — typed results and errors.
- `Tests/` — unit tests.
