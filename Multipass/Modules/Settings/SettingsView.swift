import SwiftUI

import CompositeSocialService

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
		.scenePadding()
		.frame(minWidth: 350, minHeight: 100)
	}
}

#Preview {
	SettingsView()
}
