import SwiftUI

import CompositeSocialService
import Storage
import Settings
import UIUtility
import Valet

@MainActor
final class AppState {
	let secretStore = SecretStore.valetStore(using: Valet.mainApp())
	let accountStore: UserAccountStore
	let timelineStore: TimelineStore
	
	init() {
		self.accountStore = UserAccountStore(secretStore: secretStore)
		self.timelineStore = TimelineStore()
	}
}

@main
struct MultipassApp: App {
	@State private var appState = AppState()
	
	var body: some Scene {
		WindowGroup {
			MainAppView(appState: appState)
				.environment(appState.accountStore)
				.environment(appState.timelineStore)
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
