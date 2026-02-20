import Foundation

import OAuthenticator
import Reblog
import SocialModels
import Storage

public struct MastodonAccountDetails: Codable, Hashable, Sendable {
	public let host: String
	public let account: String
}

public struct MastodonService {
	private static let appRegistrationKey = "Mastodon App Registration"

	let clientTask: Task<MastodonClient, any Error>
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

			return MastodonClient(host: params.host, provider: authenticator.responseProvider)
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
	
	private var client: MastodonClient {
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

extension MastodonService: SocialAccount {
	public var id: String {
		// this is insufficient
		host
	}

	public var platform: SocialService {
		.mastodon
	}

	public func timeline(within range: Range<Date>, gapID: UUID, isolation: isolated (any Actor)) -> some AsyncSequence<TimelineFragment, any Error> {
		AsyncThrowingStream { [host] continuation in
			Task {
				_ = isolation
				let parser = ContentParser()

				var maxId: String? = nil
				
				/// Both bounds start at the upper bound with the newest posts.
				var fragmentLowerBound = range.upperBound
				var fragmentUpperBound = range.upperBound
				
				while true {
					do {
						let statuses = try await client.timeline(minimumId: nil, maximumId: maxId)

						/// The oldest date included in the status array. If empty the lower bound can be the distant past as there are no more.
						let statusLowerBound = statuses.last?.createdAt ?? .distantPast
						
						maxId = statuses.last?.id

						// very inefficient, but have to keep going until we find our starting point
						guard statusLowerBound < range.upperBound else {
							continue
						}

						/// posts assumed to be sorted newest to oldest
						let posts: [Post] = statuses
							.filter { range.contains($0.createdAt) }
							.compactMap { Post($0, host: host, parser: parser) }
						
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
		if post.source != .mastodon {
			return
		}

		_ = try await client.likePost(post.identifier)
	}

	public func profiles(for identifiers: [String]) async throws -> [Profile] {
		let accounts = try await client.profiles(for: identifiers)

		let parser = ContentParser()

		return accounts.map { account in
			Profile(account, host: host, parser: parser)
		}
	}
}
