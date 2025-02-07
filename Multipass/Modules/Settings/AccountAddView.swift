import SwiftUI

import CompositeSocialService
import Storage
import UIUtility

struct AccountAddView: View {
	@Environment(UserAccountStore.self) var accountStore
	@Environment(\.dismiss) private var dismiss
	@State private var details: UserAccountDetails
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
		
		self._details = State(initialValue: UserAccountDetails(host: defaultHost, user: "me"))
	}

	var body: some View {
		VStack {
			Form {
				Text("Service: \(source.rawValue)")
				TextField("Host Server", text: $details.host)
					.platform_textInputAutocapitalization(.never)
				TextField("Account", text: $details.user)
					.platform_textInputAutocapitalization(.never)
					.autocorrectionDisabled(true)
			}
			Button("Add") {
				addAccount()
			}.disabled(adding)
		}
		.padding()
	}

	private func addAccount() {
		self.adding = true

		let account = UserAccount(source: source, details: details)

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
