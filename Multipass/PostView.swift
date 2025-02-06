import SwiftUI

import CompositeSocialService

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
					Text(post.author.name)
						.fontWeight(.bold)
					Text(post.author.handle)
				}
				Text(post.content)
			}
		}
    }
}

#Preview {
	PostView(post: Post.placeholder)
}
