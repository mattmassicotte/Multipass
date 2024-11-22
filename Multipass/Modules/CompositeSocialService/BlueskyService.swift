import Foundation

import BlueskyAPI
import OAuthenticator

public struct BlueskyService: SocialService {
	let client: BlueskyAPI.Client
	let credentials: BlueskyAPI.Credentials
	
	public init(with provider: @escaping URLResponseProvider, credentials: BlueskyAPI.Credentials, secretStore: SecretStore) {
		self.credentials = credentials
		
		self.client = BlueskyAPI.Client(
			host: "bsky.social",
			handle: credentials.identifier,
			appPassword: credentials.password,
			provider: provider
		)
	}

	
	public func timeline() async throws -> [Post] {
		let session = try await client.createSession(with: credentials)
		
		let response = try await client.timeline(token: session.accessJwt)
		
		return response.feed.map { entry in
			switch entry.post.record {
			case let .post(post):
				return Post(
					content: post.text,
					source: .bluesky,
					date: entry.post.indexedAt,
					author: entry.post.author.handle,
					identifier: UUID().description
				)
			}
		}
	}
}
