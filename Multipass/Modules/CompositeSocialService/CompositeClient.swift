import Foundation

import BlueskyAPI
import MastodonAPI
import OAuthenticator

public enum DataSource: String, Hashable, Sendable, Codable, CaseIterable {
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
	
	public init(content: String, source: DataSource, date: Date, author: String, identifier: String) {
		self.content = content
		self.source = source
		self.date = date
		self.author = author
		self.identifier = identifier
	}
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
	private let secretStore: SecretStore
	public let services: [SocialService]
	
	public init(secretStore: SecretStore, services: [SocialService]) {
		self.secretStore = secretStore
		self.services = services
	}
}

extension CompositeClient: SocialService {
	public func timeline() async throws -> [Post] {
		return try await withThrowingTaskGroup(of: [Post].self) { group in
			for service in services {
				group.addTask {
					do {
						return try await service.timeline()
					} catch {
						print("failed to load timeline: \(service), \(error)")
						return []
					}
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
