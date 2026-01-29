import SwiftUI

import CompositeSocialService
import Storage
import StableView

@MainActor
@Observable
final class FeedViewModel {
	// this is needed to workaround a bug in Xcode 16.3, but my assumption is it will be resolved shortly.
	#if targetEnvironment(simulator)
	@ObservationIgnored
	private let responseProvider = URLSession(configuration: .ephemeral).responseProvider
	#else
	@ObservationIgnored
	private let responseProvider = URLSession.defaultProvider
	#endif
	@ObservationIgnored
	private let secretStore: SecretStore
	@ObservationIgnored
	private let timelineStore: TimelineStore

	@ObservationIgnored
	private var timelineModel: TimelineModel

	private(set) var accountsIdentifier: Int
	var positionAnchor: AnchoredListPosition<Post>? {
		didSet {
			if let pos = positionAnchor {
				updateServicePosition(for: pos.item)
			}
		}
	}
	
	public var timelime = CompositeTimeline()

	init(secretStore: SecretStore, timelineStore: TimelineStore) {
		self.secretStore = secretStore
		self.timelineStore = timelineStore
		
		self.accountsIdentifier = 0
		self.timelineModel = TimelineModel(services: [])
	}
	
	var servicePosition: ServicePosition? {
		timelineStore.position
	}
	
	private func updateServicePosition(for post: Post) {
		var pos = servicePosition ?? .unknown
		
		pos.date = post.date
		
		if let bskyCursor = post.blueskyCursor {
			pos.bluesky = bskyCursor
		}
		
		if let statusId = post.mastodonStatusId {
			pos.mastodon = statusId
		}
		
		timelineStore.position = pos
	}
	
	var aboveCount: Int {
		0
	}
	
	func refresh() async {
		let now = Date.now
		let range = now.addingTimeInterval(-60*60*2)..<now

		await timelineModel.fill(gap: range) { idx, state in
			print("fill state: \(idx), \(state)")
		}
	}

	func updateAccounts(_ accounts: [UserAccount]) {
		let services = accounts
			.map { (account) -> any SocialService in
				switch account.source {
				case .mastodon:
					MastodonService(
						with: responseProvider,
						host: account.details.host,
						secretStore: secretStore
					)
				case .bluesky:
					BlueskyService(
						with: responseProvider,
						authServer: account.details.host,
						account: account.details.user,
						secretStore: secretStore
					)
				}
			}

		self.timelineModel = TimelineModel(services: services)

		timelineModel.timelineHandler = {
			self.timelime = $0
		}
	}
	
	func handlePostAction(action: PostStatusAction, post: Post) {
		fatalError()
	}
}
