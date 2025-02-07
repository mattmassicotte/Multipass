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
	public let embed: Embed?
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

public enum Embed: Decodable, Hashable, Sendable {
	public struct Video: Decodable, Hashable, Sendable {
		
	}
	
	public struct VideoView: Decodable, Hashable, Sendable {
		
	}
	
	public struct AspectRatio: Decodable, Hashable, Sendable {
		public let height: Int
		public let width: Int
		
		public init(height: Int, width: Int) {
			self.height = height
			self.width = width
		}
	}
	
	public struct ImageEntry: Decodable, Hashable, Sendable {
		public struct Image: Decodable, Hashable, Sendable {
			public let mimeType: String
			public let size: Int
		}
		
		public let alt: String
		public let aspectRatio: AspectRatio
		public let langs: [String]?
		public let text: String?
		public let image: Image
	}

	public struct Images: Decodable, Hashable, Sendable {
		public let images: [ImageEntry]
	}
	
	public struct ImageViewEntry: Decodable, Hashable, Sendable {
		public struct Image: Decodable, Hashable, Sendable {
			public let thumb: String
			public let fullsize: String
			public let alt: String
			public let aspectRatio: AspectRatio
		}
		
		public let images: [Image]
	}
	
	public struct ExternalView: Decodable, Hashable, Sendable {
		public struct External: Decodable, Hashable, Sendable {
			public let uri: String
			public let title: String
			public let description: String
			public let thumb: String?
			
			public var url: URL? {
				URL(string: uri)
			}
			
			public var thumbURL: URL? {
				thumb.flatMap { URL(string: $0) }
			}
		}
		
		public let external: External
	}
	
	public struct Record: Decodable, Hashable, Sendable {
		
	}
	
	public struct RecordWithMedia: Decodable, Hashable, Sendable {
		
	}
	
	public struct RecordWithMediaView: Decodable, Hashable, Sendable {
		public let record: Record
		public let media: Embed
	}
	
	public struct RecordView: Decodable, Hashable, Sendable {
	}
	
	public struct External: Decodable, Hashable, Sendable {
	}
	
	case video(Video)
	case videoView(VideoView)
	case images(Images)
	case imagesView(ImageViewEntry)
	case external(External)
	case externalView(ExternalView)
	case recordWithMedia(RecordWithMedia)
	indirect case recordWithMediaView(RecordWithMediaView)
	case record(Record)
	case recordView(RecordView)
	
	private enum CodingKeys: String, CodingKey {
		case type = "$type"
	}
	
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let value = try container.decode(String.self, forKey: .type)
		
		switch value {
		case "app.bsky.embed.video":
			self = .video(try Video(from: decoder))
		case "app.bsky.embed.video#view":
			self = .videoView(try VideoView(from: decoder))
		case "app.bsky.embed.images":
			self = .images(try Images(from: decoder))
		case "app.bsky.embed.images#view":
			self = .imagesView(try ImageViewEntry(from: decoder))
		case "app.bsky.embed.external":
			self = .external(try External(from: decoder))
		case "app.bsky.embed.external#view":
			self = .externalView(try ExternalView(from: decoder))
		case "app.bsky.embed.recordWithMedia":
			self = .recordWithMedia(try RecordWithMedia(from: decoder))
		case "app.bsky.embed.recordWithMedia#view":
			self = .recordWithMediaView(try RecordWithMediaView(from: decoder))
		case "app.bsky.embed.record":
			self = .record(try Record(from: decoder))
		case "app.bsky.embed.record#view":
			self = .recordView(try RecordView(from: decoder))
		default:
			throw DecodingError.dataCorrupted(
				DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription: "unhandled embed type \(value)"
				)
			)

		}
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
	public let embed: Embed?
	
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

public struct TimelineResponse: Decodable, Hashable, Sendable {
	public struct FeedEntry: Decodable, Hashable, Sendable {
		public let post: Post
		public let reply: Reply?
		public let reason: FeedReason?
		public let feedContext: String?
	}
	
	public let cursor: String
	public let feed: [FeedEntry]
}
