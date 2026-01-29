import Foundation

import CompositeSocialService
import Algorithms

public struct CompositeTimeline: Hashable, Sendable {
	public typealias GapIdProvider = (String, Range<Date>) -> UUID

	public struct GapContext: Hashable, Sendable {
		public var serviceGaps: [String: Range<Date>]

		public init(_ serviceGaps: [String : Range<Date>]) {
			self.serviceGaps = serviceGaps
		}

		public init(name: String, range: Range<Date>) {
			self.serviceGaps = [name: range]
		}

		public var maximumDate: Date {
			var date = Date.distantPast

			for range in serviceGaps.values {
				date = max(range.upperBound, date)
			}

			return date
		}

		public mutating func merge(_ other: Self) {
			self.serviceGaps.merge(other.serviceGaps) { rangeA, rangeB in
				let lower = min(rangeA.lowerBound, rangeB.lowerBound)
				let upper = max(rangeA.upperBound, rangeB.upperBound)

				return lower..<upper
			}
		}
	}

	public enum Element: Hashable, Sendable, Comparable {
		case post(Post)
		case gap(UUID, GapContext)

		var date: Date {
			switch self {
			case .post(let post):
				post.date
			case .gap(_, let context):
				context.maximumDate
			}
		}

		public static func < (lhs: CompositeTimeline.Element, rhs: CompositeTimeline.Element) -> Bool {
			lhs.date < rhs.date
		}

		public static func gap(_ id: UUID, _ gaps: [String: Range<Date>]) -> Self {
			let context = GapContext(gaps)

			return .gap(id, context)
		}
	}

	public var elements: [Element]

	public init(_ elements: [Element] = []) {
		self.elements = elements
	}

	public mutating func merge(_ timeline: AccountTimeline, idProvider: GapIdProvider) {
		let newElements = timeline.elements.map { element in
			switch element {
			case .post(let post):
				return Element.post(post)
			case .gap(let range):
				let id = idProvider(timeline.serviceId, range)
				let context = GapContext([timeline.serviceId: range])

				return Element.gap(id, context)
			}
		}

		self.elements.append(contentsOf: newElements)
		self.elements.sort(by: >)
	}

	public mutating func merge(_ timelines: [AccountTimeline], idProvider: GapIdProvider) {
		for subtimeline in timelines {
			merge(subtimeline, idProvider: idProvider)
		}
	}

	public mutating func consolidateGaps() {
		var index = elements.startIndex

		while index < elements.endIndex {
			let nextIndex = elements.index(after: index)
			if nextIndex >= elements.endIndex {
				break
			}

			let current = elements[index]
			let next = elements[nextIndex]

			switch (current, next) {
			case (.post, _):
				break
			case (.gap, .post):
				break
			case (.gap(let idA, var context), .gap(let idB, let other)):
				// return the id which has the smallest maximum date, because I *think* that should result
				// in the longest-lived gap ids
				let id = context.maximumDate <= other.maximumDate ? idA : idB

				context.merge(other)

				elements[index] = .gap(id, context)
				elements.remove(at: nextIndex)
				continue
			}

			index = nextIndex
		}
	}
}

extension CompositeTimeline.Element: Identifiable {
	public var id: String {
		switch self {
		case .post(let post):
			post.id
		case .gap(let id, _):
			id.uuidString
		}
	}
}

extension CompositeTimeline.Element: CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self {
		case .post(let post):
			"<Post \(post.id) \(post.date)>"
		case .gap(let id, let context):
			"<Gap \(id) \(context)>"
		}
	}
}

extension CompositeTimeline {
	public init(timelines: [AccountTimeline], idProvider: GapIdProvider) {
		self.init()

		merge(timelines, idProvider: idProvider)
		consolidateGaps()
	}
}
