import Foundation

public struct CompositePost: Hashable, Identifiable, Sendable {
	public var posts: Set<Post>
	public let id: UUID

	public init(id: UUID, posts: Set<Post>) {
		self.id = UUID()
		self.posts = posts
	}

	public init(post: Post) {
		self.init(id: UUID(), posts: [post])
	}

	public mutating func merge(_ post: Post) {
		self.posts.insert(post)
	}
}

extension CompositePost: Comparable {
	public var date: Date {
		posts.min()?.date ?? .now
	}

	var sortValue: (Date, ID) {
		(date, id)
	}

	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.sortValue < rhs.sortValue
	}
}
