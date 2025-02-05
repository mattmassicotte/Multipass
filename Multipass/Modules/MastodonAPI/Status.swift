import Foundation

public struct ReblogStatus: Decodable, Hashable, Sendable, Identifiable {
	public let id: String
	public let createdAt: Date
	public let content: String
	public let account: Account
	public let language: String?
	public let reblogs: Int
	public let favorites: Int
	
	enum CodingKeys: String, CodingKey {
		case id
		case createdAt = "created_at"
		case content
		case account
		case language
		case reblogs = "reblogs_count"
		case favorites = "favourites_count"
	}
}

public struct Status: Decodable, Hashable, Sendable, Identifiable {
	public let id: String
	public let createdAt: Date
	public let content: String
	public let account: Account
	public let language: String?
	public let reblogs: Int
	public let favorites: Int
	public let reblog: ReblogStatus?
	
	enum CodingKeys: String, CodingKey {
		case id
		case createdAt = "created_at"
		case content
		case account
		case language
		case reblogs = "reblogs_count"
		case favorites = "favourites_count"
		case reblog
	}
	
	public var effectiveContent: String {
		if let reblog {
			return reblog.content
		}
		
		return content
	}
}

public struct Account: Decodable, Hashable, Sendable, Identifiable {
	public struct Field: Decodable, Hashable, Sendable {
		public let name: String
		public let value: String
		public let verifiedAt: Date?
		
		enum CodingKeys: String, CodingKey {
			case name
			case value
			case verifiedAt = "verified_at"
		}
	}
	
	public let id: String
	public let displayName: String
	public let username: String
	public let fields: [Field]
	
	enum CodingKeys: String, CodingKey {
		case id
		case displayName = "display_name"
		case username
		case fields
	}
}
