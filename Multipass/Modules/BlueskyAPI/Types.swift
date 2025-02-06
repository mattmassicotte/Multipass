import Foundation

public typealias ATProtoDID = String
public typealias ATProtoURI = String
public typealias ATProtoCID = String

public enum AccountStatus: String, Decodable, Hashable, Sendable {
	case takenDown = "takendown"
	case suspended
	case deactivated
}

public enum Record: Hashable, Sendable {
	case post(PostRecord)
}

extension Record: Decodable {
	private enum CodingKeys: String, CodingKey {
		case type = "$type"
	}
	
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let value = try container.decode(String.self, forKey: .type)
		
		switch value {
		case "app.bsky.feed.post":
			self = .post(try PostRecord(from: decoder))
		default:
			throw DecodingError.dataCorrupted(
				DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription: "unhandled record type \(value)"
				)
			)
		}
	}
}

public enum Feature: Decodable, Hashable, Sendable {
	public struct Mention: Decodable, Hashable, Sendable {
		public let did: ATProtoDID
	}
	
	public struct Tag: Decodable, Hashable, Sendable {
		public let tag: String
	}
	
	public struct Link: Decodable, Hashable, Sendable {
		public let uri: String
	}
	
	case link(Link) // app.bsky.richtext.facet#link
	case tag(Tag) // app.bsky.richtext.facet#tag
	case mention(Mention) // app.bsky.richtext.facet#mention
	
	private enum CodingKeys: String, CodingKey {
		case type = "$type"
	}
	
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let value = try container.decode(String.self, forKey: .type)
		
		switch value {
		case "app.bsky.richtext.facet#mention":
			self = .mention(try Mention(from: decoder))
		case "app.bsky.richtext.facet#tag":
			self = .tag(try Tag(from: decoder))
		case "app.bsky.richtext.facet#link":
			self = .link(try Link(from: decoder))
		default:
			throw DecodingError.dataCorrupted(
				DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription: "unhandled feature type \(value)"
				)
			)

		}
	}
}

public struct Facet: Decodable, Hashable, Sendable {
	public struct Index: Decodable, Hashable, Sendable {
		public let byteStart: Int
		public let byteEnd: Int
	}
	
	public let features: [Feature]
	public let index: Index
}

public struct PostRecord: Decodable, Hashable, Sendable {
	public let createdAt: Date
	public let langs: [String]?
	public let text: String
	public let facets: [Facet]?
}

public struct Author: Decodable, Hashable, Sendable {
	public let did: ATProtoDID
	public let handle: String
	public let displayName: String
	public let avatar: String?
	
	public var avatarURL: URL? {
		avatar.flatMap { URL(string: $0) }
	}
}

public struct Post: Decodable, Hashable, Sendable {
	public struct Viewer: Decodable, Hashable, Sendable {
		public let repost: ATProtoURI?
		public let like: ATProtoURI?
		public let threadMuted: Bool?
		public let replyDisabled: Bool?
		public let embeddingDisabled: Bool?
		public let pinned: Bool?
	}
	
	public struct Label: Decodable, Hashable, Sendable {
		public let version: Int
		public let uri: ATProtoURI
		public let cid: ATProtoCID?
		public let value: String
		public let negation: Bool?
		public let createdAt: Date
		public let expiresAt: Date?
		public let signature: String?
		
		enum CodingKeys: String, CodingKey {
			case version = "ver"
			case uri
			case cid
			case value = "val"
			case negation = "neg"
			case createdAt = "cts"
			case expiresAt = "exp"
			case signature = "sig"
		}
	}
	
	public let uri: ATProtoURI
	public let cid: ATProtoCID
	public let author: Author
	public let record: Record
	public let replyCount: Int
	public let repostCount: Int
	public let likeCount: Int
	public let quoteCount: Int
	public let indexedAt: Date
	public let viewer: Viewer
	public let labels: [Label]?
	
	public var url: URL? {
		guard let rkey = uri.components(separatedBy: "/").last else {
			return nil
		}
		
		let handle = author.handle
		
		return URL(string: "https://bsky.app/profile/\(handle)/post/\(rkey)")
	}
}

public struct Reply: Decodable, Hashable, Sendable {
	public struct ReplyObject: Decodable, Hashable, Sendable {
		public let uri: ATProtoURI
		public let cid: ATProtoCID?
	}
	
	public let root: ReplyObject
	public let parent: ReplyObject
	public let grandparentAuthor: Author?
}


