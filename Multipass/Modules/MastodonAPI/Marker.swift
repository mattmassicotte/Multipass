import Foundation

public struct Marker: Decodable, Hashable, Sendable {
	public enum Timeline: String, Codable, Hashable, Sendable {
		case home = "home"
		case notifications = "notifications"
	}
	
	public let lastReadId: String
	public let version: Int
	public let updatedAt: Date
	
	enum CodingKeys: String, CodingKey {
		case lastReadId = "last_read_id"
		case version
		case updatedAt = "updated_at"
	}
}

public struct MarkerResponse: Decodable, Hashable, Sendable {
	public let home: Marker?
	public let notifications: Marker?
}
