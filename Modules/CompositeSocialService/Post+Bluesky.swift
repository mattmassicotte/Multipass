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

extension Handle {
	init(atProtoHandle: String) {
		let components = atProtoHandle.split(separator: ".")
		if components.count > 2 {
			self.init(
				host: components.suffix(2).joined(separator: "."),
				name: components.prefix(components.count - 2).joined(separator: "."),
				platform: .bluesky
			)
		} else {
			self.init(host: atProtoHandle, name: "", platform: .bluesky)
		}
	}
}

extension Author {
	init(_ profile: App.Bsky.Actor.Defs.ProfileViewBasic) {
		self.init(
			name: profile.displayName ?? "",
			platformId: profile.did,
			handle: Handle(atProtoHandle: profile.handle),
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

extension Profile {
	init(_ profile: App.Bsky.Actor.Defs.ProfileViewDetailed) {
		self.handle = Handle(atProtoHandle: profile.handle)
		self.avatarURL = profile.avatarURL
		self.displayName = profile.displayName ?? ""
		self.references = []
		self.platformId = profile.did
	}
}
