import Foundation

import OAuthenticator
import Storage

public typealias URLResponseProvider = OAuthenticator.URLResponseProvider

public typealias SocialServiceID = String

public protocol SocialService: Identifiable {
	associatedtype TimelineSequence: AsyncSequence<TimelineFragment, Error>
	
	var id: SocialServiceID { get }
	var platform: SocialPlatform { get }

	func timeline(within range: Range<Date>, gapID: UUID, isolation: isolated (any Actor)) -> TimelineSequence
	
	func likePost(_ post: Post) async throws

	func profiles(for identifiers: [String]) async throws -> [Profile]
}

extension SocialService {
	public func profile(for identifier: String) async throws -> Profile {
		try await profiles(for: [identifier]).first!
	}
}
