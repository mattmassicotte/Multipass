import Foundation

public struct Author: Hashable, Sendable {
	public let name: String
	public let handle: Handle
	public let platformId: String
	public let avatarURL: URL?

	public init(name: String, platformId: String, handle: Handle, avatarURL: URL? = nil) {
		self.name = name
		self.platformId = platformId
		self.handle = handle
		self.avatarURL = avatarURL
	}

	public init(
		name: String,
		platformId: String,
		handle: String,
		host: String,
		platform: SocialPlatform,
		avatarURL: URL? = nil
	) {
		self.init(
			name: name,
			platformId: platformId,
			handle: Handle(host: host, name: handle, platform: platform),
			avatarURL: avatarURL,
		)
	}

	public static let placeholder = Author(name: "placeholder", platformId: "1", handle: .placeholder)
}
