import SwiftUI

import CompositeSocialService
import Storage
import Settings
import UIUtility
import Valet

@MainActor
@Observable
final class AppState {
	@ObservationIgnored
	let secretStore = SecretStore.valetStore(using: Valet.mainApp())
	
	@ObservationIgnored
	let accountStore: UserAccountStore
	
	init() {
		self.accountStore = UserAccountStore(secretStore: secretStore)
	}
}

@main
struct MultipassApp: App {
	@State private var appState = AppState()
	
	
	var body: some Scene {
		WindowGroup {
			MainAppView(appState: appState)
				.environment(appState.accountStore)
		}
		.commands {
			MenuCommands()
		}

#if os(macOS)
		Settings {
			SettingsView()
		}
		.environment(appState.accountStore)
#endif
	}
}
