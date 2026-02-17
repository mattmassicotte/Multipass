import Foundation

import CompositeSocialService
import Algorithms

public struct CompositeTimeline: Hashable, Sendable {
	public enum Element: Hashable, Sendable, Comparable {
		case post(Post)
		case gap(Gap)
		
		/// Value used when sorting. Items must always sort the same way so multiple values are used to ensure order never flip flops if two share the same date.
		var sortValue: (upperBound: Date, lowerBound: Date, id: String) {
			switch self {
			case .post(let post):
				(
					upperBound: post.date,
					lowerBound: post.date,
					id: post.id
				)
			case .gap(let gap):
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
	
	public var serviceIDs: Set<SocialServiceID>
	
	/// Posts sorted from newest to oldest
	public var posts: [Post]
	/// Gaps sorted from oldest to newest
	public var gaps: [Gap]
	/// Posts and gaps sorted from newest to oldest
	public var elements: [Element] = []
	
	public var timelineRange: Range<Date>?
	

	public init(
		serviceIDs: Set<SocialServiceID> = [],
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
	
	mutating public func addGapLoadingNewest(maxTimeframe: TimeInterval = 60*60*2) -> Gap {
		let now = Date.now
		let lowerBound = timelineRange?.upperBound ?? now.addingTimeInterval(-abs(maxTimeframe))
		
		return addGap(range: lowerBound..<now, loadingStatus: .loading)
	}
	
	public mutating func addGap(range: Range<Date>, loadingStatus: Gap.LoadingStatus) -> Gap {
		let gap = Gap(id: UUID(), range: range, serviceIDs: serviceIDs, loadingStatus: loadingStatus)
		gaps.insert(gap)
		if let timelineRange {
			self.timelineRange = Swift.min(timelineRange.lowerBound, range.lowerBound)..<Swift.max(timelineRange.upperBound, range.upperBound)
		} else {
			self.timelineRange = gap.range
		}
		return gap
	}
	
	public mutating func updateGap(id: Gap.ID, _ loadingStatus: Gap.LoadingStatus) {
		guard let index = gaps.firstIndex(where: { $0.id == id }) else {
			return
		}
		
		gaps[index].loadingStatus = loadingStatus
	}
	
	public mutating func update(with fragment: TimelineFragment) throws {
		guard let gapIndex = gaps.firstIndex(where: { $0.id == fragment.gapID }) else {
			print("Fragment returned without a matching gap id \(fragment.gapID)")
			return
		}
		try gaps[gapIndex].updateRanges(with: fragment)
		posts.update(with: fragment.posts)
		updateElements()
	}
	
	public mutating func removeGap(id: Gap.ID) {
		gaps = gaps.filter { $0.id != id }
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
		
		print("Updated Elements - Posts: \(posts.count) Gaps: \(gaps.count) Elements: \(elements.count)")
	}
}


extension CompositeTimeline.Element: Identifiable {
	public var id: String {
		switch self {
		case let .post(post):
			"post - \(post.id)"
		case let .gap(gap):
			"gap - \(gap.id.uuidString)"
		}
	}
	
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
