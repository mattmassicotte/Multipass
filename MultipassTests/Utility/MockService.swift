import Foundation

import CompositeSocialService

final class MockService: SocialAccount {
	let fragments: [TimelineFragment]
	let profiles: [Profile]
	let id: String

	init(id: String, fragments: [TimelineFragment], profiles: [Profile] = []) {
		self.id = id
		self.fragments = fragments
		self.profiles = profiles
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

	func profiles(for identifiers: [String]) async throws -> [CompositeSocialService.Profile] {
		profiles
	}
}
