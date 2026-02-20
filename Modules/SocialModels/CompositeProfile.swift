import Foundation

import Utility

public struct CompositeProfile: Sendable {
	public let avatarURL: URL?
	public let handles: Set<Handle>
	public let name: String

	public init(name: String, handles: Set<Handle>, avatarURL: URL? = nil) {
		self.avatarURL = avatarURL
		self.handles = handles
		self.name = name
	}

	public init(profile: Profile) {
		self.avatarURL = profile.avatarURL
		self.name = profile.displayName
		self.handles = [profile.handle]
	}

	public init(author: Author) {
		self.avatarURL = author.avatarURL
		self.name = author.name
		self.handles = [author.handle]
	}
}

extension CompositeProfile {
	public enum Similarity: Hashable, Sendable {
		case dissimilar
		case similar
		case same
	}

	public func compare(to author: Author, on platform: SocialService) -> Similarity {
		var similar = false

		for handle in handles {
			if handle == author.handle {
				return .same
			}

			if handle.name.similarity(to: author.handle.name) > 0.8 {
				similar = true
			}

			if handle.host.similarity(to: author.handle.name) > 0.8 {
				similar = true
			}

			if handle.name.similarity(to: author.handle.host) > 0.8 {
				similar = true
			}
		}

		return similar ? .similar : .dissimilar
	}
}
