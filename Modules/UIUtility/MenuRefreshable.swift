import SwiftUI

@MainActor
struct MenuRefreshable: ViewModifier {
	let handler: () async -> Void

	func body(content: Content) -> some View {
		content
#if os(macOS)
			.focusedSceneValue(\.refreshAction) {
				Task {
					await handler()
				}
			}
#else
			.refreshable {
				await handler()
			}
#endif
	}
}

extension View {
	/// A `refreshable` modifier that can also respond to `refreshAction`
	public func menuRefreshable(handler: @escaping () async -> Void) -> some View {
		modifier(MenuRefreshable(handler: handler))
	}
}
