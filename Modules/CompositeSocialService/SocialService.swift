import Foundation

import OAuthenticator
import Storage

public typealias URLResponseProvider = OAuthenticator.URLResponseProvider

public typealias TimelineFragment = [Post]

public protocol SocialService {
	associatedtype TimelineSequence: AsyncSequence<TimelineFragment, Error>

	var id: String { get }

	func timeline(within range: Range<Date>, isolation: isolated (any Actor)) -> TimelineSequence
	func likePost(_ post: Post) async throws
}
