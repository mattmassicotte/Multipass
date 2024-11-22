import Foundation

import BlueskyAPI
import MastodonAPI
import OAuthenticator
import Valet
import Utility

public enum DataSource: Hashable, Sendable {
	case mastodon
	case bluesky
}

extension DataSource: CustomStringConvertible {
	public var description: String {
		switch self {
		case .mastodon: "Mastodon"
		case .bluesky: "Bluesky"
		}
	}
}

public struct Post: Hashable, Sendable {
	public let content: String
	public let source: DataSource
	public let date: Date
	public let author: String
	public let identifier: String
}

extension Post: Identifiable {
	public var id: String {
		"\(source)-\(identifier)"
	}
}

extension Post: Comparable {
	public static func < (lhs: Post, rhs: Post) -> Bool {
		lhs.date < rhs.date
	}
}

public typealias URLResponseProvider = OAuthenticator.URLResponseProvider

public protocol SocialService: Sendable {
	func timeline() async throws -> [Post]
}

public struct CompositeClient {
	private let responseProvider: URLResponseProvider
	private let secretStore: SecretStore
	private let services: [SocialService]
	
	public init(responseProvider: @escaping URLResponseProvider, secretStore: SecretStore, services: [SocialService]) {
		self.responseProvider = responseProvider
		self.secretStore = secretStore
		self.services = services
	}
}

extension CompositeClient: SocialService {
	public func timeline() async throws -> [Post] {
		try await withThrowingTaskGroup(of: [Post].self) { group in
			for service in services {
				group.addTask {
					try await service.timeline()
				}
			}
			
			var posts = [Post]()
			
			for try await result in group {
				posts += result
			}
			
			return posts
		}
	}
}