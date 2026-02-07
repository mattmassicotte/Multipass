import Foundation

import CompositeSocialService

final class MockService: SocialService {
	let fragments: [TimelineFragment]
	let id: String

	init(id: String, fragments: [TimelineFragment]) {
		self.id = id
		self.fragments = fragments
	}

	convenience init(id: String, fragment: TimelineFragment) {
		self.init(id: id, fragments: [fragment])
	}

	public func timeline(
		within range: Range<Date>,
		gapID: UUID,
		isolation: isolated (any Actor) = #isolation
	) -> some AsyncSequence<TimelineFragment, any Error> {
		AsyncThrowingStream { [fragments] continuation in
			for fragment in fragments {
				continuation.yield(fragment)
			}

			continuation.finish()
		}
	}

	func likePost(_ post: Post) async throws {
	}
}
