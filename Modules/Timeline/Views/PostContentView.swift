import SwiftUI

struct PostContentView: View {
	let content: AttributedString
	
    var body: some View {
		Text(content)
			.fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
	PostContentView(content: "It's light. Handle's adjustable for easy carrying, good for righties and lefties. Breaks down into four parts, undetectable by x-ray, ideal for quick, discreet interventions. A word on firepower. Titanium recharger, three thousand round clip with bursts of three to three hundred, and with the Replay button - another Zorg invention - it's even easier. One shot... https://example.com")
}
