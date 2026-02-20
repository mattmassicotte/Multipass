import Foundation
import CoreGraphics

import Storage

public enum Attachment: Hashable, Sendable {
	public struct ImageSpecifier: Hashable, Sendable {
		public let url: URL
		public let size: CGSize?
		public let focus: CGPoint?

		public init(url: URL, size: CGSize?, focus: CGPoint?) {
			self.url = url
			self.size = size
			self.focus = focus
		}
	}
	
	public struct Image: Hashable, Sendable {
		public let preview: ImageSpecifier?
		public let full: ImageSpecifier
		public let description: String?
		
		public init(preview: ImageSpecifier?, full: ImageSpecifier, description: String?) {
			self.preview = preview
			self.full = full
			self.description = description
		}
	}
	
	public struct Link: Hashable, Sendable {
		public let preview: ImageSpecifier?
		public let description: String?
		public let title: String?
		public let url: URL
		
		public init(preview: ImageSpecifier?, description: String?, title: String?, url: URL) {
			self.preview = preview
			self.description = description
			self.title = title
			self.url = url
		}
	}
	
	case images([Image])
	case link(Link)
}

public struct PostStatus: Hashable, Sendable {
	public let likeCount: Int
	public let liked: Bool
	public let repostCount: Int
	public let reposted: Bool
	
	public init(likeCount: Int, liked: Bool, repostCount: Int, reposted: Bool) {
		self.likeCount = likeCount
		self.liked = liked
		self.repostCount = repostCount
		self.reposted = reposted
	}
	
	public static let placeholder = PostStatus(likeCount: 5, liked: false, repostCount: 150, reposted: true)
}

public struct Post: Hashable, Sendable {
	public let content: AttributedString?
	public let source: DataSource
	public let date: Date
	public let author: Author
	public let repostingAuthor: Author?
	public let identifier: String
	public let url: URL?
	public let uri: String?
	public let attachments: [Attachment]
	public let status: PostStatus
	
	// service-specific things
	public let blueskyCursor: String?
	public var blueskyURI: String? { uri }
	public var mastodonStatusId: String? {
		guard source == .mastodon else {
			return nil
		}
		
		return identifier
	}
	
	public init(
		content: AttributedString?,
		source: DataSource,
		date: Date,
		author: Author,
		repostingAuthor: Author?,
		identifier: String,
		url: URL?,
		uri: String? = nil,
		attachments: [Attachment],
		status: PostStatus,
		blueskyCursor: String? = nil
	) {
		self.content = content
		self.source = source
		self.date = date
		self.author = author
		self.repostingAuthor = repostingAuthor
		self.identifier = identifier
		self.url = url
		self.uri = uri
		self.attachments = attachments
		self.status = status
		self.blueskyCursor = blueskyCursor
	}
	
	public static let placeholder = Post(
		content: "hello",
		source: .mastodon,
		date: .now,
		author: Author.placeholder,
		repostingAuthor: Author.placeholder,
		identifier: "abc123",
		url: URL(string: "https://example.com")!,
		attachments: [],
		status: .placeholder
	)
}

extension Post: Identifiable {
	public var id: String {
		"\(source)-\(identifier)"
	}
}

extension Post: Comparable {
	var sortValue: (Date, ID) {
		(date, id)
	}
	
	public static func < (lhs: Post, rhs: Post) -> Bool {
		lhs.sortValue < rhs.sortValue
	}
}

public extension Array<Post> {
	mutating func update(with newPosts: [Post]) {
		#warning("Deduplication logic here")
		self = (self + newPosts).sorted(by: >)
	}
}
