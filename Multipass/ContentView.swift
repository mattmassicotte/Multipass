import SwiftUI

import struct BlueskyAPI.Credentials
import CompositeSocialService
import Valet

@MainActor
@Observable
final class ViewModel {
	@ObservationIgnored
	private var client: CompositeClient
	@ObservationIgnored
	private var services: [any SocialService] = []
	
	private(set) var posts: [Post] = []

	init() {
		let responseProvider = URLSession.defaultProvider
		let valet = Valet.mainApp()
		let secretStore = SecretStore.valetStore(using: valet)
		
		let data = try? valet.object(forKey: "Bluesky Auth")
		let bskyCredentials = try? data.map { try JSONDecoder().decode(BlueskyAPI.Credentials.self, from: $0) }
		
		let mastodonService = MastodonService(with: responseProvider, host: "mastodon.social", secretStore: secretStore)
		let blueskyService = BlueskyService(with: responseProvider, credentials: bskyCredentials!, secretStore: secretStore)
		
		self.client = CompositeClient(
			responseProvider: responseProvider,
			secretStore: secretStore,
			services: [mastodonService, blueskyService]
		)
	}
	
	func checkActiveServices() async {
		
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
