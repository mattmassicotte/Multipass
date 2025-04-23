import SwiftUI

struct AvatarView: View {
	let url: URL?
	
    var body: some View {
		AsyncImage(url: url) { image in
			image
				.resizable()
				.aspectRatio(contentMode: .fit)
		} placeholder: {
			Image(systemName: "person.fill")
		}
		.frame(height: 40.0)
		
    }
}

#Preview {
	AvatarView(url: nil)
}
