import SwiftUI

import CompositeSocialService

struct AccountAddView: View {
	@Environment(AccountStore.self) var accountStore
	@Environment(\.dismiss) private var dismiss
	@State private var details: AccountDetails
	@State private var adding = false
	let source: DataSource
	
	init(source: DataSource) {
		self.source = source
		
		let defaultHost = switch source {
		case .mastodon:
			"mastodon.social"
		case .bluesky:
			"bsky.social"
		}
		
		self._details = State(initialValue: AccountDetails(host: defaultHost, user: "me"))
	}

	var body: some View {
		VStack {
			Form {
				Text("Service: \(source.rawValue)")
				TextField("Host Server", text: $details.host)
				TextField("Account", text: $details.user)
			}
			Button("Add") {
				addAccount()
			}.disabled(adding)
		}
		.padding()
#if !os(macOS)
		.navigationBarTitle("Add Account")
#endif
	}

	private func addAccount() {
		self.adding = true

		let account = Account(source: source, details: details)

		Task<Void, Never> {
			do {
				try await accountStore.addAccount(account)
			}
			catch {
				print("failed to add account", error)
			}

			self.adding = false
			dismiss()
		}
	}
}

#Preview {
	AccountAddView(source: .mastodon)
}
