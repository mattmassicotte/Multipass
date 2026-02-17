import Foundation

import ATAT

extension Post {
	init(_ feedViewPost: App.Bsky.Feed.Defs.FeedViewPost) {
		let repostAuthor: Author?
		let date: Date

		if case let .reasonRepost(repost) = feedViewPost.reason {
			repostAuthor = Author(repost.by)
			date = repost.indexedAt
		} else {
			repostAuthor = nil
			date = feedViewPost.post.date
		}

		let identfifier: String

		if let handle = repostAuthor?.handle {
			identfifier = feedViewPost.post.cid + "/\(handle)"
		} else {
			identfifier = feedViewPost.post.cid
		}

		self.init(
			content: feedViewPost.text,
			source: .bluesky,
			date: date,
			author: Author(feedViewPost.post.author),
			repostingAuthor: repostAuthor,
			identifier: identfifier,
			url: feedViewPost.post.url,
			uri: feedViewPost.post.uri,
			attachments: [],
			status: PostStatus(
				likeCount: feedViewPost.post.likeCount ?? 0,
				liked: feedViewPost.post.viewer.like != nil,
				repostCount: feedViewPost.post.repostCount ?? 0,
				reposted: false
			)
		)
	}
}

extension Author {
	init(_ profile: App.Bsky.Actor.Defs.ProfileViewBasic) {
		self.init(
			name: profile.displayName ?? "",
			handle: profile.handle,
			avatarURL: profile.avatarURL
		)
	}
}

extension App.Bsky.Feed.Defs.FeedViewPost {
	var text: String? {
		guard case let .post(post) = post.record else {
			return nil
		}
		
		return post.text
	}
}
