import Foundation

import ATAT

extension Post {
	init(_ feedViewPost: Bsky.Feed.FeedViewPost) {
		let repostAuthor = feedViewPost.reasonRepost.flatMap { Author($0.by) }

		let identfifier: String

		if let handle = repostAuthor?.handle {
			identfifier = feedViewPost.post.cid + "/\(handle)"
		} else {
			identfifier = feedViewPost.post.cid
		}

		self.init(
			content: feedViewPost.text,
			source: .bluesky,
			date: feedViewPost.reasonRepost?.indexedAt ??  feedViewPost.post.date,
			author: Author(feedViewPost.post.author),
			repostingAuthor: repostAuthor,
			identifier: identfifier,
			url: feedViewPost.post.url,
			uri: feedViewPost.post.uri,
			attachments: [],
			status: PostStatus(
				likeCount: feedViewPost.post.likeCount,
				liked: feedViewPost.post.viewer.like != nil,
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
