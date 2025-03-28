import Foundation

import MastodonAPI
import OAuthenticator
import Reblog

public struct MastodonAccountDetails: Codable, Hashable, Sendable {
	public let host: String
	public let account: String
}

public struct MastodonService: SocialService {
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

	public func timeline() async throws -> [Post] {
		let statusArray = try await client.timeline()
		let parser = ContentParser()
		
		return statusArray.compactMap { status -> Post? in
			// filter direct relies
			if status.inReplyToId != nil {
				return nil
			}
			
			let content: String
			
			do {
				let visibleContent = status.reblog?.content ?? status.content
				
				let components = try parser.parse(visibleContent)
				
				if case let .link(_, value) = components.first, value.hasPrefix("@") {
					return nil
				}
				
				content = parser.renderToString(components)
			} catch {
				print("failed to process:", status)
				return nil
			}
			
			let author = Author(
				name: status.account.displayName,
				handle: status.account.resolvedUsername(with: host),
				avatarURL: URL(string: status.account.avatarStatic)
			)
			
			let rebloggedAuthor = status.reblog.map {
				Author(
					name: $0.account.displayName,
					handle: $0.account.resolvedUsername(with: host),
					avatarURL: URL(string: $0.account.avatarStatic)
				)
			}
			
			let imageCollections = status.mediaAttachments.compactMap { mediaAttachment -> Attachment.Image? in
				guard mediaAttachment.type == .image else { return nil }
				guard let url = mediaAttachment.url else { return nil }
				
				return Attachment.Image(
					preview: mediaAttachment.previewURL.flatMap { .init(url: $0, size: nil, focus: nil) },
					full: .init(url: url, size: nil, focus: nil),
					description: mediaAttachment.description
				)
			}
			
			let attachments = [
				Attachment.images(imageCollections)
			]
			
			return Post(
				content: content,
				source: .mastodon,
				date: status.createdAt,
				author: author,
				repostingAuthor: rebloggedAuthor,
				identifier: status.id,
				url: URL(string: status.uri),
				attachments: attachments,
				status: PostStatus(
					likeCount: status.favorites,
					liked: status.favorited ?? false,
					repostCount: status.reblogs,
					reposted: status.reblogged ?? false
				)
			)
		}
	}
	
	public func likePost(_ post: Post) async throws {
		_ = try await client.likePost(post.identifier)
	}
}
