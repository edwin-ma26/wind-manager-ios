import Foundation

// Wind API response types — included automatically with `import WindManager`
// Use with: JSONDecoder().keyDecodingStrategy = .convertFromSnakeCase

public struct WindResponse: Decodable {
    public let id: String
    public let object: String
    public let model: String
    public let choices: [Choice]
    public let usage: Usage
    public let receipt: Receipt

    public struct Choice: Decodable {
        public let index: Int
        public let message: Message
        public let finishReason: String  // decoded from "finish_reason"

        public struct Message: Decodable {
            public let role: String
            public let content: MessageContent
        }
    }

    public struct Usage: Decodable {
        public let promptTokens: Int      // decoded from "prompt_tokens"
        public let completionTokens: Int  // decoded from "completion_tokens"
        public let totalTokens: Int       // decoded from "total_tokens"
    }

    public struct Receipt: Decodable {
        public let requestId: String         // decoded from "request_id"
        public let inputTokens: Int          // decoded from "input_tokens"
        public let outputTokens: Int         // decoded from "output_tokens"
        public let providerCostCents: Int    // decoded from "provider_cost_cents"
        public let userChargeCents: Int      // decoded from "user_charge_cents"
        public let devShareCents: Int        // decoded from "dev_share_cents"
        public let platformFeeCents: Int     // decoded from "platform_fee_cents"
        public let featureId: String         // decoded from "feature_id"
        public let model: String
    }
}

// Message content is either a plain string or an array of parts (text or image)
public enum MessageContent: Decodable {
    case text(String)
    case parts([ContentPart])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .text(string)
        } else {
            self = .parts(try container.decode([ContentPart].self))
        }
    }

    public var string: String? {
        if case .text(let s) = self { return s }
        return nil
    }
}

public struct ContentPart: Decodable {
    public let type: String
    public let text: String?
    public let imageUrl: ImageUrl?  // decoded from "image_url"

    public struct ImageUrl: Decodable {
        public let url: String
    }
}
