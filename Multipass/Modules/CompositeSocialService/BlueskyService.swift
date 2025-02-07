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

			return BlueskyAPI.Client(host: resolvedPDS, provider: authenticator.responseProvider)
		}
	}

	private static func resolve(handle: String) async throws -> String {
		let resolver = ATResolver()
		
		let details = try await resolver.resolveHandle(handle)
		
		guard let pds = details?.serviceEndpoint else {
			print("failed to resolve PDS for \(handle)")

			throw BlueskyServiceError.pdsResolutionFailed(handle)
		}
		
		return String(pds.dropFirst("https://".count))
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

		return response.feed.compactMap { entry in
			if entry.reply != nil {
				return nil
			}
			
			switch entry.post.record {
			case let .post(post):
				let author = Author(
					name: entry.post.author.displayName,
					handle: entry.post.author.handle,
					avatarURL: entry.post.author.avatarURL
				)
				
				let postingAuthor = entry.repostingAuthor.map {
					Author(
						name: $0.displayName,
						handle: $0.handle,
						avatarURL: $0.avatarURL
					)
				}
				
				let attachment = entry.post.embed?.toAttachment()
				let attachments = [attachment].compactMap { $0 }
				
				return Post(
					content: post.text,
					source: .bluesky,
					date: entry.post.indexedAt,
					author: author,
					repostingAuthor: postingAuthor,
					identifier: entry.post.cid,
					url: entry.post.url,
					attachments: attachments
				)
			}
		}
	}
}

extension TimelineResponse.FeedEntry {
	var repostingAuthor: FeedReasonRepost.Profile? {
		if case let .feedReasonRepost(value) = reason {
			return value.by
		}
		
		return nil
	}
}

extension Embed {
	func toAttachment() -> Attachment? {
		switch self {
		case let .imagesView(entry):
			let images = entry.images.map { atImage in
				let fullsize = Attachment.ImageSpecifier(
					url: URL(string: atImage.fullsize)!,
					size: CGSize(width: atImage.aspectRatio.width, height: atImage.aspectRatio.height),
					focus: nil
				)
				
				let preview = Attachment.ImageSpecifier(
					url: URL(string: atImage.thumb)!,
					size: nil,
					focus: nil
				)
				
				return Attachment.Image(
					preview: preview,
					full: fullsize,
					description: atImage.alt
				)
			}
			
			return Attachment.images(images)
		case let .recordWithMediaView(entry):
			return entry.media.toAttachment()
		default:
			return nil
		}
	}
}
