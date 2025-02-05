import SwiftUI

import CompositeSocialService

struct AccountAddView: View {
	@Environment(AccountStore.self) var accountStore
	@Environment(\.dismiss) private var dismiss
	@State private var details = AccountDetails(host: "host.social", user: "me")
	@State private var adding = false
	let source: DataSource

	private var pdsBinding: Binding<String> {
		Binding<String> {
			details.values["PDS"] ?? ""
		} set: { value in
			details.values["PDS"] = value
		}

	}
	
	var body: some View {
		VStack {
			Form {
				Text("Service: \(source.rawValue)")
				TextField("Host Server", text: $details.host)
				TextField("Account", text: $details.user)
				if source == .bluesky {
					TextField("PDS", text: pdsBinding)
				}
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
