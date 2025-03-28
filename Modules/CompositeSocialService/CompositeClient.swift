import Foundation

import OAuthenticator

public typealias URLResponseProvider = OAuthenticator.URLResponseProvider

public protocol SocialService: Sendable {
	func timeline() async throws -> [Post]
	func likePost(_ post: Post) async throws
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
	
	public func likePost(_ post: Post) async throws {
		try await withThrowingTaskGroup { group in
			for service in services {
				group.addTask {
					try await service.likePost(post)
				}
			}
			
			for try await _ in group {
			}
		}
	}
}
