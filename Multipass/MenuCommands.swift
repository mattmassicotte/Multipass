import SwiftUI

import UIUtility

struct MenuCommands: Commands {
	@FocusedValue(\.refreshAction) var refreshAction
	
	var body: some Commands {
		CommandGroup(after: .pasteboard) {
			Divider()
			Button("Refresh") {
				refreshAction?()
			}
			.keyboardShortcut("r")
			.disabled(refreshAction == nil)
		}
	}
}
