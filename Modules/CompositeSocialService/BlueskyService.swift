import CryptoKit
import Foundation

import ATResolve
import BlueskyAPI
import OAuthenticator
import Storage

public struct BlueskyAccountDetails: Codable, Hashable, Sendable {
	/// This is the user's PDS
	public let host: String
	public let account: String
}

enum BlueskyServiceError: Error {
	case pdsResolutionFailed(String)
	case uriMissing
}

struct ClientParams {
	let provider: URLResponseProvider
	let authServer: String
	let pds: String?
	let account: String
	let secretStore: SecretStore
}

public class BlueskyService {
	private static let dpopKey = "Bluesky DPoP Key"
	public static let clientMetadataEndpoint = "https://downloads.chimehq.com/com.chimehq.Multipass/client-metadata.json"

	private var clientResult: Result<BlueskyAPI.Client, any Error>?
	let clientParams: ClientParams

	public init(
		with provider: @escaping URLResponseProvider,
		authServer: String,
		pds: String? = nil,
		account: String,
		secretStore: SecretStore
	) {
		self.clientParams = ClientParams(provider: provider, authServer: authServer, pds: pds, account: account, secretStore: secretStore)
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

	private static func createClient(with params: ClientParams) async throws -> BlueskyAPI.Client {
		let loginStore = params.secretStore.loginStore(for: "Bluesky OAuth")

		let key = try await Self.loadDPoPKey(with: params.secretStore)

		// these three steps should be done on account creation
		let clientConfig = try await ClientMetadata.load(for: Self.clientMetadataEndpoint, provider: params.provider)
		let serverConfig = try await ServerMetadata.load(for: params.authServer, provider: params.provider)

		// this is necessary because ?? doesn't work with async calls appearently?
		let resolvedPDS: String

		if let pds = params.pds {
			resolvedPDS = pds
		} else {
			resolvedPDS = try await Self.resolve(handle: params.account)
		}

		let tokenHandling = Bluesky.tokenHandling(
			account: params.account,
			server: serverConfig,
			jwtGenerator: DPoPSigner.JSONWebTokenGenerator(dpopKey: key)
		)

		let config = Authenticator.Configuration(
			appCredentials: clientConfig.credentials,
			loginStorage: loginStore,
			tokenHandling: tokenHandling
		)

		let authenticator = Authenticator(config: config)

		return BlueskyAPI.Client(host: resolvedPDS, account: params.account, provider: authenticator.responseProvider)
	}

	private static func loadDPoPKey(with store: SecretStore) async throws -> DPoPKey {
		do {
			if let data = try await store.read(Self.dpopKey) {
				return try JSONDecoder().decode(DPoPKey.self, from: data)
			}
		} catch {
			print("failed to get existing DPoP key", error)
		}

		let key = DPoPKey.P256()

		let keyData = try JSONEncoder().encode(key)

		try await store.write(keyData, Self.dpopKey)

		return key
	}

	private var client: BlueskyAPI.Client {
		get async throws {
			if let result = clientResult {
				return try result.get()
			}

			return try await Self.createClient(with: clientParams)
		}
	}
	
	public func timeline(from position: ServicePosition, newer: Bool) async throws -> [Post] {
		assert(newer == true, "older isn't supported yet")
		let response = try await client.timeline(cursor: position.bluesky)

		return response.feed.compactMap { entry in
			if entry.reply != nil {
				return nil
			}
			
			return Post(entry)
		}
	}
}

extension BlueskyService: SocialService {
	public var id: String {
		clientParams.account
	}

	public func timeline(within range: Range<Date>, gapID: UUID, isolation: isolated (any Actor)) -> some AsyncSequence<TimelineFragment, any Error> {
		AsyncThrowingStream { continuation in
			Task {
				_ = isolation

				var cursor: String? = nil
				
				var fragmentUpperBound = range.upperBound
				var fragmentLowerBound = range.upperBound

				while true {
					do {
						let response = try await client.timeline(cursor: cursor)

						/// The oldest date included in the status array. If empty the lower bound can be the distant past as there are no more.
						let statusLowerBound = response.feed.last?.post.date ?? .distantPast

						cursor = response.cursor

						// very inefficient, but have to keep going until we find our starting point
						guard statusLowerBound < range.upperBound else {
							continue
						}

						/// posts assumed to be sorted newest to oldest
						let posts: [Post] = response.feed
							.filter { range.contains($0.post.date) }
							.map { Post($0) }
						
						if statusLowerBound < range.lowerBound {
							/// If there are older posts then the posts includes the oldest post and we can use the range lower bound.
							fragmentLowerBound = range.lowerBound
						} else if let oldestPostDate = posts.last?.date {
							/// If we don't know if there are older posts then we use the oldest post date.
							fragmentLowerBound = oldestPostDate
						} else {
							/// If the posts array is empty then we are out of posts and we use the range lower bound.
							fragmentLowerBound = range.lowerBound
						}

						/// Even if the array of posts is empty we want to yield a result to show a range of time has no posts in it.
						continuation.yield(
							TimelineFragment(
								serviceID: id,
								gapID: gapID,
								posts: posts,
								range: fragmentLowerBound..<fragmentUpperBound
							)
						)
						
						/// If this fragment reaches the lower bound of the range we are done.
						if Calendar.current.isDate(fragmentLowerBound, equalTo: range.lowerBound, toGranularity: .second) {
							break
						}
						
						/// After submitting a fragment, we reset the upper bound to equal the previous lower bound.
						fragmentUpperBound = fragmentLowerBound

					} catch {
						continuation.finish(throwing: error)
						break
					}
				}

				continuation.finish()
			}
		}
	}

	public func likePost(_ post: Post) async throws {
		if post.source != .bluesky {
			return
		}

//		guard let uri = post.uri else {
//			throw BlueskyServiceError.uriMissing
//		}

//		_ = try await client.likePost(cid: post.identifier, uri: uri)
		fatalError("nope")
	}
}
