import SwiftUI

import CompositeSocialService

struct PostAttachmentView: View {
	let attachments: [Attachment]
	
	var body: some View {
		ForEach(attachments, id: \.hashValue) { attachment in
			switch attachment {
			case let .images(collection):
				ForEach(collection, id: \.hashValue) { imageDetails in
					AsyncImage(url: imageDetails.preview?.url) { image in
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
					} placeholder: {
						Image(systemName: "photo.fill")
					}
					.frame(width: 226)
					.border(Color.gray)
				}
			case let .link(link):
				VStack {
					AsyncImage(url: link.preview?.url) { image in
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
					} placeholder: {
						Image(systemName: "photo.fill")
					}
					.frame(width: 226)
					.border(Color.gray)
					Text(link.title ?? "no title")
				}
			}
		}
	}
}
