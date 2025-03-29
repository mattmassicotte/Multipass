import CryptoKit
import Foundation

import ATResolve
import BlueskyAPI
import OAuthenticator

public struct BlueskyAccountDetails: Codable, Hashable, Sendable {
	/// This is the user's PDS
	public let host: String
	public let account: String
}

enum BlueskyServiceError: Error {
	case pdsResolutionFailed(String)
	case uriMissing
}

public actor BlueskyService: SocialService {
	private static let dpopKey = "Bluesky DPoP Key"
	public static let clientMetadataEndpoint = "https://downloads.chimehq.com/com.chimehq.Multipass/client-metadata.json"

	let clientTask: Task<BlueskyAPI.Client, any Error>

	public init(
		with provider: @escaping URLResponseProvider,
		authServer: String,
		pds: String? = nil,
		account: String,
		secretStore: SecretStore
	) {
		self.clientTask = Task<BlueskyAPI.Client, any Error> {
			let loginStore = secretStore.loginStore(for: "Bluesky OAuth")

			let key = try await Self.loadDPoPKey(with: secretStore)

			// these three steps should be done on account creation
			let clientConfig = try await ClientMetadata.load(for: Self.clientMetadataEndpoint, provider: provider)
			let serverConfig = try await ServerMetadata.load(for: authServer, provider: provider)

			// this is necessary because ?? doesn't work with async calls appearently?
			let resolvedPDS: String
			
			if let pds {
				resolvedPDS = pds
			} else {
				resolvedPDS = try await Self.resolve(handle: account)
			}

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

			return BlueskyAPI.Client(host: resolvedPDS, account: account, provider: authenticator.responseProvider)
		}
	}

	private static func resolve(handle: String) async throws -> String {
		let resolver = ATResolver()
		
		let details = try await resolver.resolveHandle(handle)
		
		guard let pdsURL = details?.personalDataServerURL else {
			print("failed to resolve PDS for \(handle)")

			throw BlueskyServiceError.pdsResolutionFailed(handle)
		}
		
		guard
			let components = URLComponents(url: pdsURL, resolvingAgainstBaseURL: false),
			let host = components.host
		else {
			print("failed to get pds url components \(handle)")

			throw BlueskyServiceError.pdsResolutionFailed(handle)
		}
		
		return host
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

	private var client: BlueskyAPI.Client {
		get async throws {
			try await clientTask.value
		}
	}
	
	public func timeline() async throws -> [Post] {
		let response = try await client.timeline()

		return response.feed.compactMap { entry in
			Post(entry)
		}
	}
	
	public func likePost(_ post: Post) async throws {
		if post.source != .bluesky {
			return
		}
		
		guard let uri = post.uri else {
			throw BlueskyServiceError.uriMissing
		}
		
		_ = try await client.likePost(cid: post.identifier, uri: uri)
	}
}
