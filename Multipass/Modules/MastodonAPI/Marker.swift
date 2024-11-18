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
	
	public init(lastReadId: String, version: Int, updatedAt: Date) {
		self.lastReadId = lastReadId
		self.version = version
		self.updatedAt = updatedAt
	}
}

public struct MarkerResponse: Decodable, Hashable, Sendable {
	public let home: Marker?
	public let notifications: Marker?
	
	public init(home: Marker?, notifications: Marker?) {
		self.home = home
		self.notifications = notifications
	}
}
