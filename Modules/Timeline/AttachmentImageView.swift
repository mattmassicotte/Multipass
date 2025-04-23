import SwiftUI

struct AttachmentImageView: View {
	let url: URL?
	
	var body: some View {
		LoadedImageView(url: url, placeholderName: "photo.fill")
			.frame(idealWidth: 226, maxWidth: 400, idealHeight: 226, maxHeight: 400)
			.border(Color.gray)
	}
}
