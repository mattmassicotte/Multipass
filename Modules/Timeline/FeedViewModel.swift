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

	private(set) var accountsIdentifier: Int
	var positionAnchor: AnchoredListPosition<Post>? {
		didSet {
			if let pos = positionAnchor {
				updateServicePosition(for: pos.item)
			}
		}
	}
	
	public var services: [any SocialService] = []
	
	public var timeline = CompositeTimeline()
	
	public var gapTasks: [Gap.ID: Task<Void, Never>] = [:]

	init(secretStore: SecretStore, timelineStore: TimelineStore) {
		self.secretStore = secretStore
		self.timelineStore = timelineStore
		
		self.accountsIdentifier = 0
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
	
	public func refresh() async {
		let newGap = timeline.addGapLoadingNewest()
		fill(newGap)
	}
	
	public func fill(_ gap: Gap) {
		gapTasks[gap.id] = Task {
			defer {
				gapTasks.removeValue(forKey: gap.id)
			}
			
			do {
				try await withTaskCancellationHandler {
					
					for service in services {
						let serviceTimeline = service.timeline(within: gap.range, gapID: gap.id, isolation: #isolation)
						
						for try await fragment in serviceTimeline {
							try Task.checkCancellation()
							try timeline.update(with: fragment)
						}
					}
				} onCancel: {
					// Maybe update gap status to stopped or paused?
				}
			} catch {
				timeline.updateGap(id: gap.id, .error)
				// Update gap with error
			}
			
			print("Timeline: \(timeline.elements.count)")
		}
	}
	

	func updateAccounts(_ accounts: [UserAccount]) {
		services = accounts
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
		timeline.serviceIDs = Set(services.map(\.id))
	}
	
	func handlePostAction(action: PostStatusAction, post: Post) {
		fatalError()
	}
}

