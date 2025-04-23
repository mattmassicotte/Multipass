import SwiftUI

import CompositeSocialService

struct PostAttachmentView: View {
	let attachments: [Attachment]
	
	var body: some View {
		HStack {
			ForEach(attachments, id: \.hashValue) { attachment in
				switch attachment {
				case let .images(collection):
					HStack {
						ForEach(collection, id: \.hashValue) { imageDetails in
							LoadedImageView(url: imageDetails.preview?.url, placeholderName: "photo.fill")
								.frame(idealWidth: 226, idealHeight: 226)
								.border(Color.gray)
						}
					}
				case let .link(link):
					VStack {
						LoadedImageView(url: link.preview?.url, placeholderName: "photo.fill")
							.frame(idealWidth: 226, idealHeight: 226)
							.border(Color.gray)
						Text(link.title ?? "no title")
					}
				}
			}
		}
	}
}
