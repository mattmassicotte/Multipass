import SwiftUI

import CompositeSocialService

struct PostView: View {
	let post: Post
	let actionHandler: PostStatusView.ActionHandler
	
	var body: some View {
		HStack(alignment: .top) {
			AvatarView(url: post.author.avatarURL)
			VStack(alignment: .leading) {
				PostContentView(post: post)
				PostStatusView(
					source: post.source,
					status: post.status,
					actionHandler: actionHandler
				)
				.padding(EdgeInsets(top: 2.0, leading: 0.0, bottom: 0.0, trailing: 0.0))
			}
			.padding(EdgeInsets(top: 0.0, leading: 4.0, bottom: 0.0, trailing: 0.0))
		}
	}
}

#Preview {
	PostView(post: Post.placeholder, actionHandler: { _ in })
}
