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
				Text(post.author)
					.fontWeight(.bold)
				Text(post.content)
			}
		}
    }
}

#Preview {
	PostView(post: Post(content: "hello", source: .mastodon, date: .now, author: "Me", identifier: "abc123"))
}
