import SwiftUI

import Settings
import Timeline

struct MainAppView: View {
	let appState: AppState
	@State private var settingsVisible = false
	
#if os(macOS)
	var body: some View {
		VStack {
			FeedView(secretStore: appState.secretStore)
		}
		.padding()
	}
#else
	var body: some View {
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
			.environment(appState.accountStore)
		}
		.sheet(isPresented: $settingsVisible) {
			SettingsView()
				.environment(appState.accountStore)
		}
		
	}
#endif
}
