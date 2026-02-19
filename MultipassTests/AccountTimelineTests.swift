import Testing
import Foundation

import CompositeSocialService
import Timeline

//extension AccountTimeline.Element {
//	static func gap(_ range: Range<TimeInterval>) -> Self {
//		let dateRange = Date(timeIntervalSince1970: range.lowerBound)..<Date(timeIntervalSince1970: range.upperBound)
//
//		return Self.gap(dateRange)
//	}
//}
//
//struct AccountTimelineTests {
//	@Test
//	func mergeSinglePostIntoEmpty() throws {
//		var timeline = AccountTimeline(id: "a")
//
//		timeline.merge(
//			dateLimit: Date(0.0),
//			[
//				Post(id: "1", time: 10.0)
//			],
//		)
//
//		let expected: [AccountTimeline.Element] = [
//			.post(Post(id: "1", time: 10.0)),
//		]
//
//		#expect(expected == timeline.elements)
//	}
//
//	@Test
//	func mergeSinglePost() throws {
//		var timeline = AccountTimeline(
//			id: "a",
//			[
//				.post(Post(id: "1", time: 10.0)),
//			]
//		)
//
//		timeline.merge(
//			dateLimit: Date(0.0),
//			[
//				Post(id: "2", time: 20.0)
//			],
//		)
//
//		let expected: [AccountTimeline.Element] = [
//			.post(Post(id: "2", time: 20.0)),
//			.post(Post(id: "1", time: 10.0)),
//		]
//
//		#expect(expected == timeline.elements)
//	}
//
//	@Test
//	func mergeSinglePostThatFillsGap() throws {
//		var timeline = AccountTimeline(
//			id: "a",
//			[
//				.post(Post(id: "2", time: 20.0)),
//				.gap(0.0..<20.0)
//			]
//		)
//
//		timeline.merge(
//			dateLimit: Date(0.0),
//			[
//				Post(id: "1", time: 10.0),
//			],
//		)
//
//		let expected: [AccountTimeline.Element] = [
//			.post(Post(id: "2", time: 20.0)),
//			.post(Post(id: "1", time: 10.0)),
//		]
//
//		#expect(expected == timeline.elements)
//	}
//
//	@Test
//	func mergeSinglePostThatReducesGap() throws {
//		var timeline = AccountTimeline(
//			id: "a",
//			[
//				.post(Post(id: "2", time: 20.0)),
//				.gap(0.0..<20.0),
//			]
//		)
//
//		timeline.merge(
//			dateLimit: Date(5.0),
//			[
//				Post(id: "1", time: 10.0),
//			]
//		)
//
//		let expected: [AccountTimeline.Element] = [
//			.post(Post(id: "2", time: 20.0)),
//			.post(Post(id: "1", time: 10.0)),
//			.gap(0.0..<5.0),
//		]
//
//		#expect(expected == timeline.elements)
//	}
//
//	@Test
//	func mergeSinglePostThatAddsGap() throws {
//		var timeline = AccountTimeline(
//			id: "a",
//			[
//				.post(Post(id: "1", time: 10.0)),
//			]
//		)
//
//		timeline.merge(
//			dateLimit: Date(30.0),
//			[
//				Post(id: "2", time: 50.0),
//			],
//		)
//
//		let expected: [AccountTimeline.Element] = [
//			.post(Post(id: "2", time: 50.0)),
//			.gap(10.0..<30.0),
//			.post(Post(id: "1", time: 10.0)),
//		]
//
//		#expect(expected == timeline.elements)
//	}
//}
