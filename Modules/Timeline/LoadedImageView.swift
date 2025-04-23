import SwiftUI

struct LoadedImageView: View {
	let url: URL?
	let placeholderName: String
	
	init(url: URL?, placeholderName: String = "person.fill") {
		self.url = url
		self.placeholderName = placeholderName
	}
	
    var body: some View {
		AsyncImage(url: url) { image in
			image
				.resizable()
				.aspectRatio(contentMode: .fit)
		} placeholder: {
			Image(systemName: placeholderName)
		}
    }
}

#Preview {
    LoadedImageView(url: URL(string: "https://robohash.org/abc.png")!)
}
