import SwiftUI

import CompositeSocialService

struct PostContentView: View {
	let post: Post
	
    var body: some View {
		VStack(alignment: .leading) {
			Text(attributedContent)
				.fixedSize(horizontal: false, vertical: true)
				.padding(insets)
			PostAttachmentView(attachments: post.attachments)
		}
    }
	
	var insets: EdgeInsets {
		EdgeInsets(top: 4.0, leading: 2.0, bottom: 4.0, trailing: 1.0)
	}
	
	var attributedContent: AttributedString {
		AttributedString(post.content ?? "")
	}
}

#Preview {
	PostContentView(
		post: Post(
			content: "hello",
			source: .mastodon,
			date: .now,
			author: Author(name: "author", handle: "me@me"),
			repostingAuthor: nil,
			identifier: "1234",
			url: nil,
			attachments: [],
			status: PostStatus(likeCount: 0, liked: false, repostCount: 0, reposted: false)
		)
	)
}
