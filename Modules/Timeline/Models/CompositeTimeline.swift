import Foundation

import CompositeSocialService
import Algorithms

public struct CompositeTimeline: Hashable, Sendable {
	public enum Element: Hashable, Sendable {
		case post(Post)
		case gap(Gap)
	}
	
	public var serviceIDs: Set<SocialAccountID>
	
	/// Posts sorted from newest to oldest
	public var posts: [Post]
	/// Gaps sorted from oldest to newest
	public var gaps: [Gap]
	/// Posts and gaps sorted from newest to oldest
	public var elements: [Element] = []
	
	public var timelineRange: Range<Date>?
	
	
	public init(
		serviceIDs: Set<SocialAccountID> = [],
		posts: [Post] = [],
		gaps: [Gap] = [],
		timelineRange: Range<Date>? = nil
	) {
		self.serviceIDs = serviceIDs
		self.posts = posts
		self.gaps = gaps
		self.timelineRange = timelineRange
		self.updateElements()
	}
}

extension CompositeTimeline {
	enum Action {
		case loadRecent(maxTimeInterval: TimeInterval)
		case loadOlder(timeInterval: TimeInterval)
	}
}

extension CompositeTimeline {
	mutating func addGapForNewest(maxTimeInterval: TimeInterval = .hours(4)) -> Gap.ID {
		let now = Date.now
		let lowerBound = timelineRange?.upperBound ?? now.addingTimeInterval(-abs(maxTimeInterval))
		
		return addGap(range: lowerBound..<now)
	}
	
	mutating func addGapForOldest(timeInterval: TimeInterval) -> Gap.ID {
		let upperBound = timelineRange?.lowerBound ?? Date.now
		let lowerBound = upperBound.addingTimeInterval(-abs(timeInterval))
		
		return addGap(range: lowerBound..<upperBound)
	}
	
	mutating func addGap(range: Range<Date>) -> Gap.ID {
		if let timelineRange {
			self.timelineRange = Swift.min(timelineRange.lowerBound, range.lowerBound)..<Swift.max(timelineRange.upperBound, range.upperBound)
		} else {
			self.timelineRange = range
		}
		let id = gaps.insertNewGap(range: range, serviceIDs: serviceIDs)
		updateElements()
		return id
	}
	
	public mutating func update(with fragment: TimelineFragment) throws {
		posts.update(with: fragment.posts)
		try gaps.fill(with: fragment)
		updateElements()
	}
	
	mutating func removeGap(id: Gap.ID) throws {
		gaps = try gaps
			.filter { gap in
				if gap.id == id {
					guard gap.loadingStatus == .loaded else {
						throw Gap.Error.unloadedGapCannotBeRemoved(id: id)
					}
					return false
				}
				return true
			}
		updateElements()
	}
	
	public mutating func reveal(id: Gap.ID, from edge: TemporalEdge, to date: Date?) throws {
		guard
			let date,
			let gap = gaps[id],
			let newRange = gap.range.removing(from: edge, to: date)
		else {
			try removeGap(id: id)
			return
		}
		
		if gap.unloadedRange?.contains(date) ?? false {
			throw Gap.Error.unloadedGapCannotBeRemoved(id: id)
		}
		
		gaps[id]?.range = newRange
		updateElements()
	}
	
	public mutating func updateElements() {
		elements = (
			posts.map { Element.post($0) }
			+ gaps.reversed().map { Element.gap($0) }
		)
		.sorted(by: >)
		.reduce(into: [Element]()) { partialResult, element in
			guard let previous = partialResult.last
			else {
				partialResult = [element]
				return
			}
			
			switch (previous, element) {
			case let (.post(previousPost), .post(post)):
				// Ignore posts with duplicate ids
				if previousPost.id != post.id {
					partialResult.append(element)
				}
				
			case (_, .gap):
				partialResult.append(element)
				
			case let (.gap(previousGap), .post(post)):
				/// Only append a post if a previous gap doesn't contain it
				if !previousGap.conceals(post.date) {
					partialResult.append(element)
				}
			}
		}
		
		print("\(elements.count) Elements Updated - \(posts.count) Posts, \(gaps.count) Gaps")
	}
}

extension CompositeTimeline.Element: Comparable {
	/// Value used when sorting. Items must always sort the same way so multiple values are used to ensure order never flip flops if two share the same date.
	var sortValue: (upperBound: Date, lowerBound: Date, id: String) {
		switch self {
		case let .post(post):
			(
				upperBound: post.date,
				lowerBound: post.date,
				id: post.id
			)
		case let .gap(gap):
			(
				upperBound: gap.range.upperBound,
				lowerBound: gap.range.lowerBound,
				id: gap.id.uuidString
			)
		}
	}
	
	public static func < (lhs: Self, rhs: Self) -> Bool {
		/// Sorting by newest date first.
		lhs.sortValue < rhs.sortValue
	}
}

extension CompositeTimeline.Element: Identifiable {
	public enum ElementID: Hashable, Sendable {
		case post(Post.ID)
		case gap(Gap.ID)
	}
	
	public var id: ElementID {
		switch self {
		case let .post(post): .post(post.id)
		case let .gap(gap): .gap(gap.id)
		}
	}
}

extension CompositeTimeline.Element {
	var post: Post? {
		switch self {
		case let .post(post):
			return post
		case .gap:
			return nil
		}
	}
		
	var gap: Gap? {
		switch self {
		case let .gap(gap):
			return gap
		case .post:
			return nil
		}
	}
}

extension Array<CompositeTimeline.Element> {
	var posts: [Post] {
		compactMap { $0.post }
	}
		
	var gaps: [Gap] {
		compactMap { $0.gap }
	}
}

extension CompositeTimeline.Element: CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self {
		case let .post(post):
			"<Post \(post.id) \(post.date)>"
		case let .gap(gap):
			"<Gap \(gap.id) \(gap.range)>"
		}
	}
}
