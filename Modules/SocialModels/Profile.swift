import Foundation

public struct Profile: Hashable, Sendable {
	public struct Reference: Hashable, Sendable {
		public enum Value: Hashable, Sendable {
			case link(URL, Bool)
			case text(String)
			case githubProfile(String)
		}

		public let name: String
		public let value: Value

		public init(name: String, value: Value) {
			self.name = name
			self.value = value
		}
	}

	public let avatarURL: URL?
	public let references: [Reference]
	public let handle: Handle
	public let displayName: String
	public let platformId: String

	public init(avatarURL: URL?, references: [Reference], handle: Handle, displayName: String, platformId: String) {
		self.avatarURL = avatarURL
		self.references = references
		self.handle = handle
		self.displayName = displayName
		self.platformId = platformId
	}
	
	public var author: Author {
		Author(name: displayName, platformId: platformId, handle: handle, avatarURL: avatarURL)
	}

	public var githubProfiles: [String] {
		references.compactMap { ref in
			switch ref.value {
			case .githubProfile(let username):
				username
			default:
				nil
			}
		}
	}
}
