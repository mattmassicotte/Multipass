import SwiftUI

import CompositeSocialService

struct PostView: View {
	let post: Post
	let actionHandler: PostStatusView.ActionHandler
	
	var body: some View {
		HStack(alignment: .top) {
			AvatarView(url: post.author.avatarURL)
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
				Text(post.content ?? "")
					.padding(EdgeInsets(top: 4.0, leading: 2.0, bottom: 4.0, trailing: 1.0))
				PostAttachmentView(attachments: post.attachments)
				PostStatusView(
					source: post.source,
					status: post.status,
					actionHandler: actionHandler
				)
			}
			.contextMenu {
				if let url = post.url {
					Button("Print Link") {
						print(url)
					}
				}
			}
		}
	}
}

#Preview {
	PostView(post: Post.placeholder, actionHandler: { _ in })
}
