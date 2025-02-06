import Foundation
import CoreGraphics

public enum DataSource: String, Hashable, Sendable, Codable, CaseIterable {
	case mastodon
	case bluesky
}

extension DataSource: CustomStringConvertible {
	public var description: String {
		switch self {
		case .mastodon: "Mastodon"
		case .bluesky: "Bluesky"
		}
	}
}

public struct Author: Hashable, Sendable {
	public let name: String
	public let handle: String
	public let avatarURL: URL?
	
	public init(name: String, handle: String, avatarURL: URL? = nil) {
		self.name = name
		self.handle = handle
		self.avatarURL = avatarURL
	}
	
	public static let placeholder = Author(name: "placeholder", handle: "placeholder")
}

public struct Post: Hashable, Sendable {
	public let content: String
	public let source: DataSource
	public let date: Date
	public let author: Author
	public let identifier: String
	public let url: URL?
	
	public init(content: String, source: DataSource, date: Date, author: Author, identifier: String, url: URL?) {
		self.content = content
		self.source = source
		self.date = date
		self.author = author
		self.identifier = identifier
		self.url = url
	}
	
	public static let placeholder = Post(
		content: "hello",
		source: .mastodon,
		date: .now,
		author: Author.placeholder,
		identifier: "abc123",
		url: URL(string: "https://example.com")!
	)
}

extension Post: Identifiable {
	public var id: String {
		"\(source)-\(identifier)"
	}
}

extension Post: Comparable {
	public static func < (lhs: Post, rhs: Post) -> Bool {
		lhs.date < rhs.date
	}
}
