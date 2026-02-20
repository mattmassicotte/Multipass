import Foundation

import SocialModels

extension Post {
	init(id: String, service: SocialService = .mastodon, time: TimeInterval) {
		self.init(
			content: nil,
			source: service,
			date: Date(timeIntervalSince1970: time),
			author: .placeholder,
			repostingAuthor: nil,
			identifier: id,
			url: nil,
			attachments: [],
			status: .placeholder
		)
	}
}
