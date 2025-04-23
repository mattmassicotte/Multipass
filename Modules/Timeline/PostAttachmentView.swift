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
							AttachmentImageView(url: imageDetails.preview?.url)
						}
					}
				case let .link(link):
					VStack {
						AttachmentImageView(url: link.preview?.url)
						Text(link.title ?? "no title")
					}
				}
			}
		}
	}
}
