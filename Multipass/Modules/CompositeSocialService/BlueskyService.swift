import CryptoKit
import Foundation

import BlueskyAPI
import OAuthenticator

public actor BlueskyService: SocialService {
	private static let dpopKey = "Bluesky DPoP Key"

	let clientTask: Task<BlueskyAPI.Client, any Error>

	public init(
		with provider: @escaping URLResponseProvider,
		authServer: String,
		clientMetadataEndpoint: String,
		account: String,
		secretStore: SecretStore
	) {

		self.clientTask = Task<BlueskyAPI.Client, any Error> {
			let loginStore = secretStore.loginStore(for: "Bluesky OAuth")

			let key = try await Self.loadDPoPKey(with: secretStore)

			// these three steps should be done on account creation
			let clientConfig = try await ClientMetadata.load(for: clientMetadataEndpoint, provider: provider)
			let serverConfig = try await ServerMetadata.load(for: authServer, provider: provider)

			let pds = try await Self.resolve(handle: account)

			let tokenHandling = Bluesky.tokenHandling(
				account: account,
				server: serverConfig,
				jwtGenerator: DPoPSigner.JSONWebTokenGenerator(dpopKey: key)
			)

			let config = Authenticator.Configuration(
				appCredentials: clientConfig.credentials,
				loginStorage: loginStore,
				tokenHandling: tokenHandling
			)

			let authenticator = Authenticator(config: config)

			return BlueskyAPI.Client(host: pds, provider: authenticator.responseProvider)
		}
	}

	private static func resolve(handle: String) async throws -> String {
		// have to resolve this dynamically

		"milkcap.us-west.host.bsky.network"
	}

	private static func loadDPoPKey(with store: SecretStore) async throws -> DPoPKey {
		do {
			if let data = try await store.read(Self.dpopKey) {
				return try JSONDecoder().decode(DPoPKey.self, from: data)
			}
		} catch {
			print("failed to get existing DPoP key", error)
		}

		let key = DPoPKey()

		let keyData = try JSONEncoder().encode(key)

		try await store.write(keyData, Self.dpopKey)

		return key
	}

	public func timeline() async throws -> [Post] {
		let response = try await clientTask.value.timeline()

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
