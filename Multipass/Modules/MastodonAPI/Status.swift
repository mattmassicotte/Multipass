import Foundation

public struct Status: Decodable, Hashable, Sendable, Identifiable {
	public let id: String
	public let createdAt: Date
	public let content: String
	public let account: Account
	
	enum CodingKeys: String, CodingKey {
		case id
		case createdAt = "created_at"
		case content
		case account
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
	public let username: String
	public let fields: [Field]
}
