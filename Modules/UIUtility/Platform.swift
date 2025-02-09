import SwiftUI

#if os(macOS)
public struct TextInputAutocapitalization: Sendable {
	public static let never = TextInputAutocapitalization()
	public static let words = TextInputAutocapitalization()
	public static let sentences = TextInputAutocapitalization()
	public static let characters = TextInputAutocapitalization()
}
#endif

extension View {
	public nonisolated func platform_textInputAutocapitalization(_ autocapitalization: TextInputAutocapitalization?) -> some View {
#if os(macOS)
		self
#else
		textInputAutocapitalization(autocapitalization)
#endif
	}
}
