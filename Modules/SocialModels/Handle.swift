public struct Handle: Hashable, Sendable {
	public let host: String
	public let name: String
	public let platform: SocialService

	public init(host: String, name: String, service: SocialService) {
		self.host = host
		self.name = name
		self.platform = service
	}

	public var displayString: String {
		"\(name)@\(host)"
	}

	public static let placeholder = Handle(host: "placeholder.com", name: "placeholder", service: .mastodon)
}

extension Handle: CustomStringConvertible {
	public var description: String {
		"\(platform):\(name)@\(host)"
	}
}
