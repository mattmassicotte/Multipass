import Foundation

import SocialModels

final class MockService: SocialAccount {
	let fragments: [TimelineFragment]
	let profiles: [Profile]
	let id: String
	let platform: SocialService

	init(id: String, service: SocialService, fragments: [TimelineFragment], profiles: [Profile] = []) {
		self.id = id
		self.fragments = fragments
		self.profiles = profiles
		self.platform = service
	}

	convenience init(id: String, service: SocialService, fragment: TimelineFragment) {
		self.init(id: id, service: service, fragments: [fragment])
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

	func profiles(for identifiers: [String]) async throws -> [Profile] {
		profiles
	}
}
