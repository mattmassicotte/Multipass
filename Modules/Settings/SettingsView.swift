import SwiftUI

import SocialClients

public struct SettingsView: View {
	public init() {
	}
	
	public var body: some View {
		TabView {
			Tab("Accounts", systemImage: "gear") {
				AccountSettingsView()
			}
			Tab("Other", systemImage: "star") {
				Text("nothing yet!")
			}
		}
#if os(macOS)
		.scenePadding()
		.frame(minWidth: 350, minHeight: 100)
#endif
	}
}

#Preview {
	Text("Settings View")
	
	/// Unable to preview Settings view as the environment requires code from the Multipass app level
//	@Previewable @State var accountStore = UserAccountStore(secretStore: SecretStore.valetStore(using: Valet.mainApp()))
//	
//	SettingsView()
//		.environment(appState.accountStore)
}
