import SwiftUI

import CompositeSocialService
import Settings
import Storage
import Timeline
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
	@State private var settingsVisible = false
	@State private var actions = MenuActions()
	
	var body: some Scene {
		WindowGroup {
#if os(macOS)
			VStack {
				FeedView(secretStore: appState.secretStore)
			}
			.padding()
#else
			NavigationStack {
				VStack {
					FeedView(secretStore: appState.secretStore)
				}
				.toolbar {
					Button {
						settingsVisible = true
					} label: {
						Image(systemName: "gear")
					}
					
				}
			}
			.sheet(isPresented: $settingsVisible) {
				SettingsView()
					.environment(appState.accountStore)
			}
#endif
		}
		.environment(appState.accountStore)
		.environment(actions)
		.commands {
			MenuCommands(actions: actions)
		}

#if os(macOS)
		Settings {
			SettingsView()
		}
		.environment(appState.accountStore)
#endif
	}
}
