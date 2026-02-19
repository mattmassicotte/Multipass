import Foundation

import Reblog

extension Reblog.Account {
	func resolveHandle(with local: String) -> Handle {
		if username == fullUsername {
			return Handle(host: local, name: username, platform: .mastodon)
		}

		let prefixLength = username.count + 1
		let host = fullUsername.suffix(fullUsername.count - prefixLength)

		return Handle(host: String(host), name: username, platform: .mastodon)
	}
}

extension Author {
	init(account: Reblog.Account, host: String) {
		let handle = account.resolveHandle(with: host)

		self.init(
			name: account.displayName,
			platformId: account.id,
			handle: handle,
			avatarURL: URL(string: account.avatarStatic)
		)
	}
}

extension Post {
	init?(_ status: Status, host: String, parser: ContentParser) {
		let content: AttributedString

		do {
			let visibleContent = status.reblog?.content ?? status.content

			let components = try parser.parse(visibleContent)

			if case let .link(_, value) = components.first, value.hasPrefix("@") {
				return nil
			}
			
			content = components.reduce(into: AttributedString()) { partialResult, component in
				var attributedString: AttributedString
				switch component {
				case let .text(string):
					attributedString = AttributedString(string)
				case let .link(url, string):
					attributedString = AttributedString(string)
					attributedString.link = url
				case .seperator:
					attributedString = AttributedString("\n")
				}
				partialResult.append(attributedString)
			}
		} catch {
			print("failed to process:", status)
			return nil
		}

		let author = Author(account: status.account, host: host)
		let rebloggedAuthor = status.reblog.map {
			Author(account: $0.account, host: host)
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

extension Profile.Reference.Value {
	init(field: String, parser: ContentParser) {
		let htmlComponents: [HTMLComponent]

		do {
			htmlComponents = try parser.parse(field)
		} catch {
			print("failed to parse field: ", error, field)
			self = .text(field)
			return
		}

		guard
			htmlComponents.count == 1,
			case .link(let url, let text) = htmlComponents.first
		else {
			self = .text(field)
			return
		}

		self = .text(field)
		return
	}
}

extension Profile.Reference {
	init(field: Account.Field, parser: ContentParser) {
		self.name = field.name

		let htmlComponents: [HTMLComponent]

		do {
			htmlComponents = try parser.parse(field.value)
		} catch {
			print("failed to parse field: ", error, field)
			self.value = .text(field.value)
			return
		}

		guard
			htmlComponents.count == 1,
			case .link(let url, _) = htmlComponents.first
		else {
			self.value = .text(field.value)
			return
		}

		switch url.host() {
		case "github.com":
			guard
				field.verifiedAt != nil,
				url.pathComponents.count == 2,
				let name = url.pathComponents.last
			else {
				self.value = .link(url, false)
				return
			}

			self.value = .githubProfile(name)
		default:
			self.value = .link(url, field.verifiedAt != nil)
		}
	}
}

extension Profile {
	init(_ account: Account, host: String, parser: ContentParser) {
		self.displayName = account.displayName
		self.avatarURL = URL(string: account.avatarStatic)
		self.handle = account.resolveHandle(with: host)
		self.references = account.fields.map { Profile.Reference(field: $0, parser: parser) }
		self.platformId = account.id
	}
}
