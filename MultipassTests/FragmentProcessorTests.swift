import Foundation
import Testing

import SocialModels
import Timeline

extension FragmentProcessor {
	func merge(_ a: Post, _ b: Post) async throws -> [Set<Post>] {
		let fragment = TimelineFragment(
			serviceID: "abc",
			gapID: UUID(),
			posts: [b],
			range: Date.distantPast..<Date.distantFuture
		)

		let mergedPosts = try await merge(
			fragment: fragment,
			with: [CompositePost(post: a)]
		)

		return mergedPosts.map { $0.posts }
	}
}

struct FragmentProcessorTests {
	@Test
	func sameAuthorSimilarContent() async throws {
		let date = Date.now

		let authorA = Author(name: "Korben", platformId: "1", handle: "korbendallas", host: "zorg.social", platform: .mastodon)
		let postA = Post(
			content: "I just want to drive a cab",
			source: .mastodon,
			date: date,
			author: authorA,
			identifier: "1",
			url: nil,
			status: .placeholder,
		)

		let authorB = Author(name: "Korben", platformId: "a", handle: "", host: "korben.dallas", platform: .bluesky)
		let postB = Post(
			content: "I just want to drive a cab",
			source: .bluesky,
			date: date,
			author: authorB,
			identifier: "a",
			url: nil,
			status: .placeholder
		)

		let identity = CompositeProfile(
			name: "Korben Dallas",
			handles: [
				authorA.handle,
				authorB.handle
			]
		)

		let processor = FragmentProcessor(authorResolver: { _ in
			identity
		})

		let mergedPosts = try await processor.merge(postA, postB)

		#expect(mergedPosts == [Set([postA, postB])])
	}

	@Test
	func similarAuthorSimilarContent() async throws {
		let date = Date.now

		let authorA = Author(name: "Korben", platformId: "1", handle: "korbendallas", host: "zorg.social", platform: .mastodon)
		let postA = Post(
			content: "I just want to drive a cab",
			source: .mastodon,
			date: date,
			author: authorA,
			identifier: "1",
			url: nil,
			status: .placeholder,
		)

		let authorB = Author(name: "Korben", platformId: "a", handle: "", host: "korben.dallas", platform: .bluesky)
		let postB = Post(
			content: "I just want to drive a cab",
			source: .bluesky,
			date: date,
			author: authorB,
			identifier: "a",
			url: nil,
			status: .placeholder
		)

		let processor = FragmentProcessor()

		let mergedPosts = try await processor.merge(postA, postB)

		#expect(mergedPosts == [Set([postA, postB])])
	}

	@Test
	func sameAuthorDissimilarContentSameLink() async throws {
		let date = Date.now

		let authorA = Author(name: "Korben", platformId: "1", handle: "korbendallas", host: "zorg.social", platform: .mastodon)
		let postA = Post(
			content: "I just want to drive a cab",
			source: .mastodon,
			date: date,
			author: authorA,
			identifier: "1",
			url: nil,
			attachments: [
				.link(
					Attachment.Link(
						preview: nil,
						description: nil,
						title: nil,
						url: URL(string: "https://zorgindustries.com/jobs/?utm_brand=korbendallas&utm_social-type=owned&utm_source=mastodon&utm_medium=social")!
					)
				),
			],
			status: .placeholder,
		)

		let authorB = Author(name: "Korben", platformId: "a", handle: "", host: "korben.dallas", platform: .bluesky)
		let postB = Post(
			content: "",
			source: .bluesky,
			date: date,
			author: authorB,
			identifier: "a",
			url: nil,
			attachments: [
				.link(
					Attachment.Link(
						preview: nil,
						description: nil,
						title: nil,
						url: URL(string: "https://zorgindustries.com/jobs/?utm_source=bsky&utm_medium=social")!
					)
				),
			],

			status: .placeholder
		)

		let identity = CompositeProfile(
			name: "Korben Dallas",
			handles: [
				authorA.handle,
				authorB.handle
			]
		)

		let processor = FragmentProcessor(authorResolver: { _ in
			identity
		})

		let mergedPosts = try await processor.merge(postA, postB)

		#expect(mergedPosts == [Set([postA, postB])])
	}

	@Test
	func differentAuthorSimilarContentSameLink() async throws {
		// controlling time here is a little more important for a stable sort order
		let date = Date.now

		let authorA = Author(name: "Korben", platformId: "1", handle: "korbendallas", host: "zorg.social", platform: .mastodon)
		let postA = Post(
			content: "That job stability tho",
			source: .mastodon,
			date: date,
			author: authorA,
			identifier: "1",
			url: nil,
			attachments: [
				.link(
					Attachment.Link(
						preview: nil,
						description: nil,
						title: nil,
						url: URL(string: "https://zorgindustries.com/jobs/")!
					)
				),
			],
			status: .placeholder,
		)

		let authorB = Author(name: "Leeloo", platformId: "a", handle: "", host: "5thelement.social", platform: .mastodon)
		let postB = Post(
			content: "That job stability tho",
			source: .bluesky,
			date: date.addingTimeInterval(-1),
			author: authorB,
			identifier: "a",
			url: nil,
			attachments: [
				.link(
					Attachment.Link(
						preview: nil,
						description: nil,
						title: nil,
						url: URL(string: "https://zorgindustries.com/jobs/")!
					)
				),
			],

			status: .placeholder
		)

		let processor = FragmentProcessor()

		let mergedPosts = try await processor.merge(postA, postB)

		#expect(mergedPosts == [Set([postA]), Set([postB])])
	}

	@Test
	func sameAuthorDissimilarContent() async throws {
		let date = Date.now

		let authorA = Author(name: "Korben", platformId: "1", handle: "korbendallas", host: "zorg.social", platform: .mastodon)
		let postA = Post(
			content: "I just want to drive a cab",
			source: .mastodon,
			date: date,
			author: authorA,
			identifier: "1",
			url: nil,
			status: .placeholder,
		)

		let authorB = Author(name: "Korben", platformId: "a", handle: "", host: "korben.dallas", platform: .bluesky)
		let postB = Post(
			content: "That job stability tho",
			source: .bluesky,
			date: date.addingTimeInterval(-1),
			author: authorB,
			identifier: "a",
			url: nil,
			status: .placeholder
		)

		let identity = CompositeProfile(
			name: "Korben Dallas",
			handles: [
				authorA.handle,
				authorB.handle
			]
		)

		let processor = FragmentProcessor(authorResolver: { _ in
			identity
		})

		let mergedPosts = try await processor.merge(postA, postB)

		#expect(mergedPosts == [Set([postA]), Set([postB])])
	}

	@Test(.disabled("for future consideration"))
	func similarAuthorSimilarPartialContent() async throws {
		let date = Date.now

		let authorA = Author(name: "Korben", platformId: "1", handle: "korbendallas", host: "zorg.social", platform: .mastodon)
		let postA = Post(
			content: "I just want to drive a cab",
			source: .mastodon,
			date: date,
			author: authorA,
			identifier: "1",
			url: nil,
			status: .placeholder,
		)

		let authorB = Author(name: "Korben", platformId: "a", handle: "", host: "korben.dallas", platform: .bluesky)
		let postB = Post(
			content: "I just ",
			source: .bluesky,
			date: date,
			author: authorB,
			identifier: "a",
			url: nil,
			status: .placeholder
		)

		let postC = Post(
			content: "want to drive",
			source: .bluesky,
			date: date,
			author: authorB,
			identifier: "b",
			url: nil,
			status: .placeholder
		)

		let postD = Post(
			content: "a cab",
			source: .bluesky,
			date: date,
			author: authorB,
			identifier: "c",
			url: nil,
			status: .placeholder
		)

		let processor = FragmentProcessor()

		let fragment = TimelineFragment(
			serviceID: "abc",
			gapID: UUID(),
			posts: [postB, postC, postD],
			range: Date.distantPast..<Date.distantFuture
		)
		let mergedPosts = try await processor.merge(fragment: fragment, with: [CompositePost(post: postA)])

		#expect(mergedPosts.map { $0.posts } == [Set([postA, postB, postC, postD])])
	}

	@Test(.disabled("for future consideration"))
	func sameAuthorSimilarPartialContent() async throws {
		let date = Date.now

		let authorA = Author(name: "Korben", platformId: "1", handle: "korbendallas", host: "zorg.social", platform: .mastodon)
		let postA = Post(
			content: "I just want to drive a cab",
			source: .mastodon,
			date: date,
			author: authorA,
			identifier: "1",
			url: nil,
			status: .placeholder,
		)

		let authorB = Author(name: "Korben", platformId: "a", handle: "", host: "korben.dallas", platform: .bluesky)
		let postB = Post(
			content: "I just ",
			source: .bluesky,
			date: date,
			author: authorB,
			identifier: "a",
			url: nil,
			status: .placeholder
		)

		let postC = Post(
			content: "want to drive",
			source: .bluesky,
			date: date,
			author: authorB,
			identifier: "b",
			url: nil,
			status: .placeholder
		)

		let postD = Post(
			content: "a cab",
			source: .bluesky,
			date: date,
			author: authorB,
			identifier: "c",
			url: nil,
			status: .placeholder
		)

		let identity = CompositeProfile(
			name: "Korben Dallas",
			handles: [
				authorA.handle,
				authorB.handle
			]
		)

		let processor = FragmentProcessor(authorResolver: { _ in
			identity
		})

		let fragment = TimelineFragment(
			serviceID: "abc",
			gapID: UUID(),
			posts: [postB, postC, postD],
			range: Date.distantPast..<Date.distantFuture
		)
		let mergedPosts = try await processor.merge(fragment: fragment, with: [CompositePost(post: postA)])

		#expect(mergedPosts.map { $0.posts } == [Set([postA, postB, postC, postD])])
	}
}
