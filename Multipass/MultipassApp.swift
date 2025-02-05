import SwiftUI

import CompositeSocialService
import Settings
import Valet

@MainActor
@Observable
final class AppState {
	@ObservationIgnored
	let secretStore = SecretStore.valetStore(using: Valet.mainApp())
	
	@ObservationIgnored
	let accountStore: AccountStore
	
	init() {
		self.accountStore = AccountStore(secretStore: secretStore)
	}
}

@main
struct MultipassApp: App {
	@State var appState = AppState()
	
	var body: some Scene {
		WindowGroup {
			VStack {
				FeedView(secretStore: appState.secretStore)
			}
			.padding()
		}
		.environment(appState.accountStore)

#if os(macOS)
		Settings {
			SettingsView()
		}
		.environment(appState.accountStore)
#endif
	}
}
