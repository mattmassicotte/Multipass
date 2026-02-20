public struct Handle: Hashable, Sendable {
	public let host: String
	public let name: String
	public let platform: SocialPlatform

	public init(host: String, name: String, platform: SocialPlatform) {
		self.host = host
		self.name = name
		self.platform = platform
	}

	public var displayString: String {
		"\(name)@\(host)"
	}

	public static let placeholder = Handle(host: "placeholder.com", name: "placeholder", platform: .mastodon)
}

extension Handle: CustomStringConvertible {
	public var description: String {
		"\(platform):\(name)@\(host)"
	}
}
