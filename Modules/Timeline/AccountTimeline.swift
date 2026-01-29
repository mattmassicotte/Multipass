import Foundation

import CompositeSocialService
import Algorithms

public struct AccountTimeline: Hashable, Sendable {
	public enum Element: Hashable, Sendable {
		case post(Post)
		case gap(Range<Date>)
	}

	public var elements: [Element]
	public let serviceId: String

	public init(
		id: String,
		_ elements: [Element] = []
	) {
		self.serviceId = id
		self.elements = elements
	}

	var dateRange: Range<Date>? {
		guard
			let first = elements.first,
			let last = elements.last
		else {
			return nil
		}

		return  last.dateRange.lowerBound..<first.dateRange.upperBound
	}

	public mutating func merge(dateLimit: Date, _ posts: TimelineFragment) {
		guard let firstPost = posts.first else { return }

		let index = elements.partitioningIndex { post in
			post.dateRange.lowerBound < firstPost.date
		}

		let newElements = posts.map { Element.post($0) }
		self.elements.insert(contentsOf: newElements, at: index)

		// adjust or insert following gap unless we are at the end
		let followingIndex = elements.index(index, offsetBy: newElements.count)
		if followingIndex >= elements.endIndex {
			return
		}

		let following = elements[followingIndex]
		switch following {
		case .post(let post):
			if dateLimit > post.date {
				let range = post.date..<dateLimit

				self.elements.insert(.gap(range), at: followingIndex)
			}
		case .gap(let range):
			// remove the gap if it not longer applies
			if dateLimit <= range.lowerBound {
				self.elements.remove(at: followingIndex)
				break
			}

			// or agjust its range
			let newRange = range.lowerBound..<dateLimit
			self.elements[followingIndex] = .gap(newRange)
 		}
	}
}

extension AccountTimeline.Element: Comparable {
	var dateRange: Range<Date> {
		switch self {
		case .gap(let range):
			range
		case .post(let post):
			post.date..<post.date
		}
	}

	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.dateRange.upperBound < rhs.dateRange.upperBound
	}
}

extension AccountTimeline.Element: CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self {
		case .post(let post):
			"<Post \(post.id) \(post.date)>"
		case .gap(let range):
			"<Gap \(range)>"
		}
	}
}
