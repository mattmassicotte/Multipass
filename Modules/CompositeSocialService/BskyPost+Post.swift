import Foundation

import ATAT

extension Post {
	init(_ feedViewPost: Bsky.Feed.FeedViewPost) {
		self.init(
			content: feedViewPost.text,
			source: .bluesky,
			date: feedViewPost.post.date,
			author: Author(feedViewPost.post.author),
			repostingAuthor: feedViewPost.reasonRepost.flatMap { Author($0.by) },
			identifier: feedViewPost.post.cid,
			url: feedViewPost.post.url,
			uri: feedViewPost.post.uri,
			attachments: [],
			status: PostStatus(
				likeCount: feedViewPost.post.likeCount,
				liked: false,
				repostCount: feedViewPost.post.repostCount,
				reposted: false
			)
		)
	}
}

extension Author {
	init(_ profile: Bsky.Actor.ProfileViewBasic) {
		self.init(
			name: profile.displayName ?? "",
			handle: profile.handle,
			avatarURL: profile.avatarURL
		)
	}
}

extension Bsky.Feed.FeedViewPost {
	var text: String? {
		guard case let .post(post) = post.record else {
			return nil
		}
		
		return post.text
	}
}
