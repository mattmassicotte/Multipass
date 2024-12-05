import SwiftUI

import struct BlueskyAPI.Credentials
import CryptoKit
import CompositeSocialService
import OAuthenticator
import Valet

@MainActor
@Observable
final class ViewModel {
	@ObservationIgnored
	private var client: CompositeClient
	@ObservationIgnored
	private var services: [any SocialService] = []
	@ObservationIgnored
	private let secretStore = SecretStore.valetStore(using: Valet.mainApp())
	
	private(set) var posts: [Post] = []

	init() {
		let responseProvider = URLSession.defaultProvider

		let mastodonService = MastodonService(
			with: responseProvider,
			host: "mastodon.social",
			secretStore: secretStore
		) 
		let blueskyService = BlueskyService(
			with: responseProvider,
			authServer: "bsky.social",
			clientMetadataEndpoint: "https://downloads.chimehq.com/com.chimehq.Multipass/client-metadata.json",
			account: "yourhandle.com",
			secretStore: secretStore
		)

		self.client = CompositeClient(
			secretStore: secretStore,
			services: [mastodonService, blueskyService]
		)
	}
	
	func refresh() async {
		do {
			self.posts = try await client.timeline().sorted()
		} catch {
			print("dammm", error)
		}
	}
}

struct FeedView: View {
	@State private var model = ViewModel()
	
	var body: some View {
		List(model.posts) { post in
			PostView(post: post)
		}
		.refreshable {
			await model.refresh()
		}
		.task {
			await model.refresh()
		}
	}
}


struct ContentView: View {
	var body: some View {
		VStack {
			FeedView()
		}
		.padding()
	}
}

#Preview {
	ContentView()
}
