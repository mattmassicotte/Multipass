import Foundation

import MastodonAPI
import OAuthenticator
import Reblog
import Storage

public struct MastodonAccountDetails: Codable, Hashable, Sendable {
	public let host: String
	public let account: String
}

public struct MastodonService {
	private static let appRegistrationKey = "Mastodon App Registration"

	let clientTask: Task<MastodonAPI.Client, any Error>
	let host: String
	private let provider: URLResponseProvider
	
	public init(with provider: @escaping URLResponseProvider, host: String, secretStore: SecretStore) {
		let params = Mastodon.UserTokenParameters(
			host: host,
			clientName: "Multipass",
			redirectURI: "MultipassApp://mastodon/oauth",
			scopes: ["read", "write", "follow", "push"]
		)

		self.host = host
		self.provider = provider
		self.clientTask = Task {
			let loginStore = secretStore.loginStore(for: "Mastodon OAuth")

			// this should be done on account creation
			let registration = try await Self.registerApplication(parameters: params, store: secretStore, provider: provider)

			let appCreds = AppCredentials(
				clientId: registration.clientID,
				clientPassword: registration.clientSecret,
				scopes: params.scopes,
				callbackURL: URL(string: params.redirectURI)!
			)

			let config = Authenticator.Configuration(
				appCredentials: appCreds,
				loginStorage: loginStore,
				tokenHandling: Mastodon.tokenHandling(with: params)
			)

			let authenticator = Authenticator(config: config, urlLoader: provider)

			return MastodonAPI.Client(host: params.host, provider: authenticator.responseProvider)
		}
	}

	private static func registerApplication(
		parameters: Mastodon.UserTokenParameters,
		store: SecretStore,
		provider: @escaping URLResponseProvider
	) async throws -> Mastodon.AppRegistrationResponse {
		do {
			if let data = try await store.read(Self.appRegistrationKey) {
				return try JSONDecoder().decode(Mastodon.AppRegistrationResponse.self, from: data)
			}
		} catch {
			print("failed to get existing app registration", error)
		}

		let appRegistration = try await Mastodon.register(with: parameters, urlLoader: provider)

		let keyData = try JSONEncoder().encode(appRegistration)

		try await store.write(keyData, Self.appRegistrationKey)

		return appRegistration
	}
	
	private var client: MastodonAPI.Client {
		get async throws {
			try await clientTask.value
		}
	}

	public func timeline(from position: ServicePosition, newer: Bool) async throws -> [Post] {
		// this is kind of mind-bending. Our position is defined as the current loaded window.
		//
		// If we want newer statuses, then we need to set our minimum to the current maximum.
		let minId = newer ? position.mastodon : nil
		let maxId = newer ? nil : position.mastodon
		
		let statusArray = try await client.timeline(minimumId: minId, maximumId: maxId)
		let parser = ContentParser()
		
		return statusArray.compactMap { status -> Post? in
			// filter direct relies
			if status.inReplyToId != nil {
				return nil
			}
			
			return Post(status, host: host, parser: parser)
		}
	}
	

}

extension MastodonService: SocialService {
	public var id: String {
		// this is insufficient
		host
	}

	public func timeline(within range: Range<Date>, isolation: isolated (any Actor)) -> some AsyncSequence<[Post], any Error> {
		AsyncThrowingStream { [host] continuation in
			Task {
				_ = isolation
				let parser = ContentParser()

				var maxId: String? = nil

				while true {
					do {
						let statuses = try await client.timeline(minimumId: nil, maximumId: maxId)

						guard let last = statuses.last else { break }

						maxId = last.id

						// very inefficient, but have to keep going until we find our starting point
						if last.createdAt > range.upperBound {
							continue
						}

						let posts: [Post] = statuses
							.filter { range.contains($0.createdAt) }
							.compactMap { Post($0, host: host, parser: parser) }

						continuation.yield(posts)

						if last.createdAt > range.lowerBound {
							break
						}
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
		if post.source != .mastodon {
			return
		}

		_ = try await client.likePost(post.identifier)
	}
}
