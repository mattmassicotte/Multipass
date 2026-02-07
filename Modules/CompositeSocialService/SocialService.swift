import Foundation

import AsyncAlgorithms
import OAuthenticator
import Storage

public typealias URLResponseProvider = OAuthenticator.URLResponseProvider

public typealias SocialServiceID = String

public protocol SocialService: Identifiable {
	associatedtype TimelineSequence: AsyncSequence<TimelineFragment, Error>
	
	var id: SocialServiceID { get }
	
	func timeline(within range: Range<Date>, gapID: UUID, isolation: isolated (any Actor)) -> TimelineSequence
	
	func likePost(_ post: Post) async throws
}
