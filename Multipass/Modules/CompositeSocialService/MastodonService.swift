import Foundation

import MastodonAPI
import MastodonContentExtraction
import OAuthenticator

public struct MastodonService: SocialService {
	let client: MastodonAPI.Client
	
	public init(with provider: @escaping URLResponseProvider, host: String, secretStore: SecretStore) {
		let params = Mastodon.UserTokenParameters(
			host: host,
			clientName: "Multipass",
			redirectURI: "MultipassApp://mastodon/oauth",
			scopes: ["read", "write", "follow", "push"]
		)
		
		let loginStore = secretStore.loginStore(for: "Mastodon OAuth")
		
		let appCreds = AppCredentials(
			clientId: "client id",
			clientPassword: "client pass",
			scopes: params.scopes,
			callbackURL: URL(string: params.redirectURI)!
		)
		
		let config = Authenticator.Configuration(
			appCredentials: appCreds,
			loginStorage: loginStore,
			tokenHandling: Mastodon.tokenHandling(with: params)
		)
		
		let authenticator = Authenticator(config: config, urlLoader: provider)
		
		self.client = MastodonAPI.Client(host: params.host, provider: authenticator.responseProvider)
	}

	
	public func timeline() async throws -> [Post] {
		let statusArray = try await client.timeline()
		
		let processor = MastodonContentExtraction.PostExtractor()
		
		return try statusArray.map {
			let text = try processor.process($0.content)
			
			return Post(
				content: text.content,
				source: .mastodon,
				date: $0.createdAt,
				author: "me",
				identifier: UUID().description
			)
		}
	}
}
