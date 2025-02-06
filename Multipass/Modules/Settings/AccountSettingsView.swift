import SwiftUI

import CompositeSocialService

struct AccountSettingsView: View {
	@Environment(UserAccountStore.self) var accountStore
	@State private var addingMastodon = false
	@State private var addingBluesky = false

	var body: some View {
		HStack {
			VStack {
				ForEach(DataSource.allCases, id: \.self) { source in
					Button("Add \(source)") {
						switch source {
						case .mastodon:
							addingBluesky = false
							addingMastodon = true
						case .bluesky:
							addingBluesky = true
							addingMastodon = false
						}
					}
				}
				Button("Remove All") {
					Task {
						try! await accountStore.removeAllAccounts()
					}
				}
			}
			List(accountStore.accounts) { account in
				HStack {
					Text(account.source.rawValue)
					Text(account.details.host)
					Text(account.details.user)
				}
			}
		}
		.sheet(isPresented: $addingMastodon) {
			AccountAddView(source: .mastodon)
		}
		.sheet(isPresented: $addingBluesky) {
			AccountAddView(source: .bluesky)
		}
	}
}

#Preview {
	AccountSettingsView()
}
