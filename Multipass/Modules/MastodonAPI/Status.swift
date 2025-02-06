import Foundation

import SwiftSoup

public typealias HTMLContent = String

func extracHTMLText(_ html: String) -> String {
	do {
		let doc = try SwiftSoup.parse(html)
		
		return try doc.text()
	} catch {
		return ""
	}
}

public struct ReblogStatus: Decodable, Hashable, Sendable, Identifiable {
	public let id: String
	public let uri: String
	public let createdAt: Date
	public let rawContent: HTMLContent
	public let account: Account
	public let language: String?
	public let reblogs: Int
	public let favorites: Int
	
	enum CodingKeys: String, CodingKey {
		case id
		case uri
		case createdAt = "created_at"
		case rawContent = "content"
		case account
		case language
		case reblogs = "reblogs_count"
		case favorites = "favourites_count"
	}
	
	public var content: String {
		extracHTMLText(rawContent)
	}
}

public struct MediaAttachment: Decodable, Hashable, Sendable, Identifiable {
	public enum MediaType: String, Decodable, Hashable, Sendable {
		case unknown
		case image
		case gifv
		case video
		case audio
	}
	
	public struct Meta: Decodable, Hashable, Sendable {
		
	}
	
	public let id: String
	public let type: MediaType
	public let rawURL: String
	public let rawPreviewURL: String?
	public let rawRemoteURL: String?
	public let meta: Meta
	public let description: String?
	public let blurhash: String
	
	enum CodingKeys: String, CodingKey {
		case id
		case type
		case rawURL = "url"
		case rawPreviewURL = "preview_url"
		case rawRemoteURL = "remote_url"
		case meta
		case description
		case blurhash
	}
	
	public var url: URL? {
		URL(string: rawURL)
	}
	
	public var previewURL: URL? {
		rawPreviewURL.flatMap { URL(string: $0) }
	}
}

public struct Status: Decodable, Hashable, Sendable, Identifiable {
	public let id: String
	public let uri: String
	public let createdAt: Date
	public let rawContent: HTMLContent
	public let account: Account
	public let language: String?
	public let reblogs: Int
	public let favorites: Int
	public let reblog: ReblogStatus?
	public let mediaAttachments: [MediaAttachment]
	
	enum CodingKeys: String, CodingKey {
		case id
		case uri
		case createdAt = "created_at"
		case rawContent = "content"
		case account
		case language
		case reblogs = "reblogs_count"
		case favorites = "favourites_count"
		case reblog
		case mediaAttachments = "media_attachments"
	}
	
	public var content: String {
		extracHTMLText(rawContent)
	}
}

public struct Account: Decodable, Hashable, Sendable, Identifiable {
	public struct Field: Decodable, Hashable, Sendable {
		public let name: String
		public let rawValue: HTMLContent
		public let verifiedAt: Date?
		
		enum CodingKeys: String, CodingKey {
			case name
			case rawValue = "value"
			case verifiedAt = "verified_at"
		}
		
		public var value: String {
			extracHTMLText(rawValue)
		}
	}
	
	public let id: String
	public let displayName: String
	public let username: String
	public let fullUsername: String
	public let avatar: String
	public let avatarStatic: String
	
	public let fields: [Field]
	
	enum CodingKeys: String, CodingKey {
		case id
		case displayName = "display_name"
		case fullUsername = "acct"
		case username
		case fields
		case avatar
		case avatarStatic = "avatar_static"
	}
	
	public func resolvedUsername(with local: String) -> String {
		if username == fullUsername {
			return "\(username)@\(local)"
		}
		
		return fullUsername
	}
}
