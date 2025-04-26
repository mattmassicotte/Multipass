import SwiftUI

import CompositeSocialService

struct PostView: View {
	let post: Post
	let actionHandler: PostStatusView.ActionHandler
	@State private var formatter: RelativeDateTimeFormatter = {
		let formatter = RelativeDateTimeFormatter()
		
		formatter.dateTimeStyle = .named
		formatter.unitsStyle = .abbreviated

		return formatter
	}()
	
	var body: some View {
		HStack(alignment: .top) {
			AvatarView(url: post.author.avatarURL)
			VStack(alignment: .leading) {
				HStack {
					Text(post.repostingAuthor?.handle ?? post.author.handle)
						.font(.caption)
					Text(formatter.localizedString(for: post.date, relativeTo: .now))
				}
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
