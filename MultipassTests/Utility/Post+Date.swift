import Foundation

import SocialClients
import Storage

extension Post {
	init(id: String, source: DataSource = .mastodon, time: TimeInterval) {
		self.init(
			content: nil,
			source: source,
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
