import Foundation
import Testing

import CompositeSocialService
import Timeline

//struct CombinedTimelineTests {
//	@MainActor
//	@Test
//	func modelLoadFromEmpty() async throws {
//		let serviceA = MockService(
//			id: "a",
//			posts: [
//				Post(id: "2", time: 20),
//				Post(id: "4", time: 10),
//			]
//		)
//
//		let serviceB = MockService(
//			id: "b",
//			posts: [
//				Post(id: "1", time: 30),
//				Post(id: "3", time: 15),
//			]
//		)
//
//		let model = TimelineModel(
//			services: [serviceA, serviceB]
//		)
//
//		var timeline = CompositeTimeline()
//
//		model.timelineHandler = {
//			timeline = $0
//		}
//
//		await model.fill(gap: Date.distantPast..<Date.now, progress: { _, _ in })
//
//		let expected = CompositeTimeline(
//			[
//				.post(Post(id: "1", time: 30)),
//				.post(Post(id: "2", time: 20)),
//				.post(Post(id: "3", time: 15)),
//				.post(Post(id: "4", time: 10)),
//			]
//		)
//
//		#expect(timeline == expected)
//	}
//
//	@MainActor
//	@Test
//	func loadNewerPosts() async throws {
//		let serviceA = MockService(
//			id: "a",
//			posts: [
//				Post(id: "5", time: 40),
//			]
//		)
//
//		let serviceB = MockService(
//			id: "b",
//			posts: [
//				Post(id: "6", time: 50),
//			]
//		)
//
//		let model = TimelineModel(
//			pairedServices: [
//				(
//					serviceA,
//					[
//						.post(Post(id: "3", time: 20)),
//						.post(Post(id: "1", time: 10)),
//					]
//				),
//				(
//					serviceB,
//					[
//						.post(Post(id: "4", time: 30)),
//						.post(Post(id: "2", time: 15)),
//					]
//				),
//			]
//		)
//
//		var timeline = CompositeTimeline()
//
//		model.timelineHandler = {
//			timeline = $0
//		}
//
//		await model.fill(gap: Date.distantPast..<Date.now, progress: { _, _ in })
//
//		let expected = CompositeTimeline(
//			[
//			.post(Post(id: "6", time: 50)),
//			.post(Post(id: "5", time: 40)),
//			.post(Post(id: "4", time: 30)),
//			.post(Post(id: "3", time: 20)),
//			.post(Post(id: "2", time: 15)),
//			.post(Post(id: "1", time: 10)),
//		]
//			)
//
//		#expect(timeline == expected)
//	}
//
//	@MainActor
//	@Test
//	func loadNewerPostsFromOneServiceFillingGap() async throws {
//		let serviceA = MockService(
//			id: "a",
//			posts: [
//				Post(id: "3", time: 100),
//			]
//		)
//
//		let serviceB = MockService(
//			id: "b",
//			posts: [
//			]
//		)
//
//		let model = TimelineModel(
//			pairedServices: [
//				(
//					serviceA,
//					[
//						.post(Post(id: "1", time: 10)),
//					]
//				),
//				(
//					serviceB,
//					[
//						.post(Post(id: "2", time: 20)),
//					]
//				),
//			]
//		)
//
//		let gapId = UUID()
//		model.compositor = { timelines in
//			CompositeTimeline(timelines: timelines, idProvider: { _, _ in gapId })
//		}
//
//		var timeline = CompositeTimeline()
//
//		model.timelineHandler = {
//			timeline = $0
//		}
//
//		// this is simulating filling a range that doesn't extend back to our first post at 20,
//		// so a gap is left
//		let fillRange = Date(50)..<Date.now
//
//		await model.fill(gap: fillRange, progress: { _, _ in })
//
//		let expected = CompositeTimeline(
//			[
//				.post(Post(id: "3", time: 100)),
//				.gap(gapId, .init(name: "a", range: Date(10.0)..<Date(50.0))),
//				.post(Post(id: "2", time: 20)),
//				.post(Post(id: "1", time: 10)),
//			]
//		)
//
//		#expect(timeline == expected)
//	}
//
//	@MainActor
//	@Test
//	func loadNewerPostsFromTwoServicesFillingGap() async throws {
//		let serviceA = MockService(
//			id: "a",
//			posts: [
//				Post(id: "3", time: 100),
//			]
//		)
//
//		let serviceB = MockService(
//			id: "b",
//			posts: [
//				Post(id: "4", time: 120),
//			]
//		)
//
//		let model = TimelineModel(
//			pairedServices: [
//				(
//					serviceA,
//					[
//						.post(Post(id: "1", time: 10)),
//					]
//				),
//				(
//					serviceB,
//					[
//						.post(Post(id: "2", time: 20)),
//					]
//				),
//			]
//		)
//
//		let gapId = UUID()
//		model.compositor = { timelines in
//			CompositeTimeline(timelines: timelines, idProvider: { _, _ in gapId })
//		}
//
//		var timeline = CompositeTimeline()
//
//		model.timelineHandler = {
//			timeline = $0
//		}
//
//		// this is simulating filling a range that doesn't extend back to our first post at 20,
//		// so a gap is left
//		let fillRange = Date(50)..<Date.now
//
//		await model.fill(gap: fillRange, progress: { _, _ in })
//
//		let expected = CompositeTimeline(
//			[
//				.post(Post(id: "4", time: 120)),
//				.post(Post(id: "3", time: 100)),
//				.gap(gapId, ["a": Date(10.0)..<Date(50.0), "b": Date(20.0)..<Date(50.0)]),
//				.post(Post(id: "2", time: 20)),
//				.post(Post(id: "1", time: 10)),
//			]
//		)
//
//		#expect(timeline	 == expected)
//	}
//}
