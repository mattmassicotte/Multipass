import SwiftUI

struct AvatarView: View {
	let url: URL?
	
	var body: some View {
		AsyncImage(url: url) { image in
			image
				.resizable()
				.scaledToFit()
		} placeholder: {
			Image(systemName: "person.fill")
				.resizable()
				.scaledToFit()
		}
		.aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
	AvatarView(url: nil)
	AvatarView(url: URL(string: "https://robohash.org/abc.png")!)
}
