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
