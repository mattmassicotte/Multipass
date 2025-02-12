import SwiftUI

import UIUtility

struct MenuCommands: Commands {
	let actions: MenuActions
		
	var body: some Commands {
		CommandGroup(after: .pasteboard) {
			Divider()
			Button("Refresh") {
				actions.refresh?()
			}
			.keyboardShortcut("r")
			.disabled(actions.refresh == nil)
		}
	}
}
