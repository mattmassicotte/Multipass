import Foundation

import Reblog

extension Post {
	init?(_ status: Status, host: String, parser: ContentParser) {
		let content: String
		
		do {
			let visibleContent = status.reblog?.content ?? status.content
			
			let components = try parser.parse(visibleContent)
			
			if case let .link(_, value) = components.first, value.hasPrefix("@") {
				return nil
			}
			
			content = parser.renderToString(components)
		} catch {
			print("failed to process:", status)
			return nil
		}
		
		let author = Author(
			name: status.account.displayName,
			handle: status.account.resolvedUsername(with: host),
			avatarURL: URL(string: status.account.avatarStatic)
		)
		
		let rebloggedAuthor = status.reblog.map {
			Author(
				name: $0.account.displayName,
				handle: $0.account.resolvedUsername(with: host),
				avatarURL: URL(string: $0.account.avatarStatic)
			)
		}
		
		let imageCollections = status.mediaAttachments.compactMap { mediaAttachment -> Attachment.Image? in
			guard mediaAttachment.type == .image else { return nil }
			guard let url = mediaAttachment.url else { return nil }
			
			return Attachment.Image(
				preview: mediaAttachment.previewURL.flatMap { .init(url: $0, size: nil, focus: nil) },
				full: .init(url: url, size: nil, focus: nil),
				description: mediaAttachment.description
			)
		}
		
		let attachments = [
			Attachment.images(imageCollections)
		]
		
		self.init(
			content: content,
			source: .mastodon,
			date: status.createdAt,
			author: author,
			repostingAuthor: rebloggedAuthor,
			identifier: status.id,
			url: URL(string: status.uri),
			attachments: attachments,
			status: PostStatus(
				likeCount: status.favorites,
				liked: status.favorited ?? false,
				repostCount: status.reblogs,
				reposted: status.reblogged ?? false
			)
		)
	}
}
