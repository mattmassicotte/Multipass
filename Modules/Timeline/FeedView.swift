import SwiftUI

import CompositeSocialService
import OAuthenticator
import Storage
import UIUtility

@frozen
public enum ViewState<T> {
  case initial
  case error
  case loading
  case loaded(T)
}

@MainActor
@Observable
final class ViewModel {
	@ObservationIgnored
	private var client: CompositeClient
	@ObservationIgnored
	private var services: [any SocialService] = []
	@ObservationIgnored
	private let responseProvider = URLSession.defaultProvider
	@ObservationIgnored
	private let secretStore: SecretStore

	private(set) var accountsIdentifier: Int
	
	private(set) var posts: [Post] = []

	init(secretStore: SecretStore) {
		self.secretStore = secretStore
		self.client = CompositeClient(
			secretStore: secretStore,
			services: []
		)
		self.accountsIdentifier = 0
	}
	
	func refresh() async {
		do {
			self.posts = try await client.timeline().sorted(by: { $0 > $1 })
		} catch {
			print("dammm", error)
		}
	}
	
	func updateAccounts(_ accounts: [UserAccount]) {
		let services = accounts.filter { $0.source == .mastodon }.map { (account) -> any SocialService in
			switch account.source {
			case .mastodon:
				MastodonService(
					with: responseProvider,
					host: account.details.host,
					secretStore: secretStore
				)
			case .bluesky:
				BlueskyService(
					with: responseProvider,
					authServer: account.details.host,
					account: account.details.user,
					secretStore: secretStore
				)
			}
		}
		
		self.client = CompositeClient(secretStore: secretStore, services: services)
		self.accountsIdentifier = accounts.hashValue
	}
}

public struct FeedView: View {
	@State private var model: ViewModel
	@Environment(UserAccountStore.self) private var accountStore
	@Environment(MenuActions.self) private var menuActions
	
	public init(secretStore: SecretStore) {
		self._model = State(wrappedValue: ViewModel(secretStore: secretStore))
	}
	
	public var body: some View {
		List(model.posts) { post in
			PostView(post: post)
		}
		.listStyle(PlainListStyle())
		.onChange(of: accountStore.accounts, initial: true, { _, newValue in
			model.updateAccounts(newValue)
		})
		.refreshable {
			await model.refresh()
		}
		.task(id: model.accountsIdentifier) {
			await model.refresh()
		}
		.onAppear {
			menuActions.refresh = {
				Task {
					await model.refresh()
				}
			}
		}
	}
}
