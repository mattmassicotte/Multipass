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

struct PostView: View {
	let post: Post
	
    var body: some View {
		HStack {
			switch post.source {
			case .mastodon:
				Image("mastodon.clean.fill")
			case .bluesky:
				Image("bluesky")
			}
			
			VStack(alignment: .leading) {
				HStack {
					Group {
						if let author = post.repostingAuthor {
							Image(systemName: "arrow.2.squarepath")
							Text(author.name)
							
						} else {
							Text(post.author.name)
						}
					}.fontWeight(.bold)
					Text(post.author.handle)
				}
				Text(post.content)
				PostAttachmentView(attachments: post.attachments)
			}
		}
    }
}

#Preview {
	PostView(post: Post.placeholder)
}
