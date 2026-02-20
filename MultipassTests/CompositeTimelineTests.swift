import Testing
import Foundation

import SocialClients
import Timeline

//struct CompositeTimelineTests {
//	@Test
//	func mergeSinglePostIntoEmpty() throws {
//		var timeline = CompositeTimeline()
//
//		let a = AccountTimeline(
//			id: "a",
//			[
//				.post(Post(id: "1", time: 10.0))
//			]
//		)
//
//		timeline.merge(a, idProvider: { _, _ in UUID() })
//
//		let expected: [CompositeTimeline.Element] = [
//			.post(Post(id: "1", time: 10.0)),
//		]
//
//		#expect(expected == timeline.elements)
//	}
//
//	@Test
//	func mergeGaps() throws {
//		let expectedId = UUID()
//
//		var timeline = CompositeTimeline(
//			[
//				.gap(expectedId, ["a": Date(10.0)..<Date(50.0)]),
//				.gap(UUID(), ["b": Date(20.0)..<Date(50.0)]),
//			]
//		)
//
//		timeline.consolidateGaps()
//
//		#expect(timeline.elements.count == 1)
//
//		let expected = CompositeTimeline.Element.gap(expectedId, [
//			"a": Date(10.0)..<Date(50.0),
//			"b": Date(20.0)..<Date(50.0)
//		])
//
//		#expect(timeline.elements.first == expected)
//	}
//}
