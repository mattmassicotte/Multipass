public enum SocialService: String, Hashable, Sendable, Codable, CaseIterable {
	case mastodon
	case bluesky
	
	/// The symbol asset name
	public var imageName: String {
		switch self {
		case .mastodon:
			"mastodon.clean.fill"
		case .bluesky:
			"bluesky"
		}
	}
}

extension SocialService: CustomStringConvertible {
	public var description: String {
		switch self {
		case .mastodon: "Mastodon"
		case .bluesky: "Bluesky"
		}
	}
}
