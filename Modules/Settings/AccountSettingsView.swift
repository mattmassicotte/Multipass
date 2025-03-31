import SwiftUI

import CompositeSocialService
import Storage

struct AccountSettingsView: View {
	@Environment(UserAccountStore.self) var accountStore
	@State private var addingMastodon = false
	@State private var addingBluesky = false
	@State private var selection = Set<UserAccount>()

	var body: some View {
		HStack{
#if os(macOS)
			VStack{
				addMasterodonButton
				addBlueskyButton
				Button("Remove All"){
					Task{
						try await accountStore.removeAllAccounts()
					}
				}
			}
			List(selection: $selection) {
				accounts
			}
			.onDeleteCommand {
				Task{
					for account in selection {
						try? await accountStore.removeAccount(account)
					}
				}
			}
#else
			List {
				accounts
				addMasterodonButton
				addBlueskyButton
			}
#endif
		}
		.sheet(isPresented: $addingMastodon) {
			AccountAddView(source: .mastodon)
		}
		.sheet(isPresented: $addingBluesky) {
			AccountAddView(source: .bluesky)
		}
	}

	private var addBlueskyButton: some View {
		Button("Add Bluesky", image: ImageResource(name: "bluesky", bundle: Bundle.main)) {
			addingBluesky = true
		}
	}
	private var addMasterodonButton: some View {
		Button("Add Mastodon", image: ImageResource(name: "mastodon.clean.fill", bundle: Bundle.main)) {
			addingMastodon = true
		}
	}

	private var accounts: some View {
		ForEach(accountStore.accounts) { account in
			Label {
				Text(account.details.user)
				Text(account.details.host)
			} icon: {
				Image(account.source.imageName)
			}
			.tag(account)
		}
		.onDelete { idx in
			let accounts = accountStore.accounts
			Task {
				for id in idx {
					guard 0..<accounts.count ~= id else { continue }

					try? await accountStore.removeAccount(accounts[id])
				}
			}
		}
	}
}

#Preview {
	AccountSettingsView()
}
