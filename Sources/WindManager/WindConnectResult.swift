import Foundation

/// The result returned after a successful Wind Connect flow.
public struct WindConnectResult {
    /// The user's Wind wallet ID. Store this on your user record and pass it with every API request.
    public let windUserId: String

    /// The user's Wind account email, if returned.
    public let windEmail: String?

    /// The user's current wallet balance in cents, if returned.
    public let balanceCents: Int?
}
