import Foundation

public enum FeedReason: Decodable, Hashable, Sendable {
	private enum CodingKeys: String, CodingKey {
		case type = "$type"
	}
	
	case feedReasonRepost(FeedReasonRepost)
	
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let value = try container.decode(String.self, forKey: .type)
		
		switch value {
		case "app.bsky.feed.defs#reasonRepost":
			self = .feedReasonRepost(try FeedReasonRepost(from: decoder))
		default:
			throw DecodingError.dataCorrupted(
				DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription: "unhandled feed reason type \(value)"
				)
			)
		}
	}
}

public struct FeedReasonRepost: Decodable, Hashable, Sendable {
	public struct Profile: Decodable, Hashable, Sendable {
		public let did: ATProtoDID
		public let handle: String
		public let displayName: String
		public let avatar: String
		public let createdAt: Date
		
		public var avatarURL: URL? {
			URL(string: avatar)
		}
	}
	
	public let by: Profile
	public let indexedAt: Date
}
