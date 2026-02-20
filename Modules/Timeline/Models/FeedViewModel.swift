import SwiftUI

import CompositeSocialService
import SocialModels
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
	
	public var services: [any SocialAccount] = []
	
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
	
	func refresh(maxTimeInterval: TimeInterval) {
		let newGapID = timeline.addGapForNewest(maxTimeInterval: maxTimeInterval)
		do {
			try fillGap(id: newGapID)
		} catch {
			print(error.localizedDescription)
		}
	}
	
	func loadOlder(timeInterval: TimeInterval) {
		let newGapID = timeline.addGapForOldest(timeInterval: timeInterval)
		do {
			try fillGap(id: newGapID)
		} catch {
			print(error.localizedDescription)
		}
	}
	
	public func timelineAction(_ action: CompositeTimeline.Action) {
		switch action {
		case let .loadRecent(maxTimeInterval):
			refresh(maxTimeInterval: maxTimeInterval)
		case let .loadOlder(timeInterval):
			loadOlder(timeInterval: timeInterval)
		}
	}
	
	public func gapAction(_ action: Gap.Action) {
		do {
			switch action {
			case let .fill(id):
				try fillGap(id: id)
			case let .cancel(id):
				gapTasks[id]?.cancel()
				timeline.gaps[id]?.isLoading = false
			case let .reveal(id, edge, date, _):
				try timeline.reveal(id: id, from: edge, to: date)
			}
		} catch {
			print(error.localizedDescription)
		}
	}
	
	public func postAction(_ action: Post.Action) {
		do {
			switch action {
			case let .like(id):
				throw Post.Action.Error.unableToLikePost(id: id)
			case let .unlike(id):
				throw Post.Action.Error.unableToUnlikePost(id: id)
			case let .repost(id):
				throw Post.Action.Error.unableToRepostPost(id: id)
			case let .group(id, _):
				throw Post.Action.Error.unableToGroupPost(id: id)
			}
		} catch {
			print(error.localizedDescription)
		}
	}
	
	public func updateTimeline(with fragment: TimelineFragment) throws {
		try timeline.update(with: fragment)
	}
	
	public func updateTimelineElements() {
		timeline.updateElements()
	}
	
	public func fillGap(id: Gap.ID) throws {
		guard gapTasks[id] == nil else {
			throw Gap.Error.gapAlreadyBeingFilled(id: id)
		}
		guard let gap = timeline.gaps[id] else {
			throw Gap.Error.noGapMatching(id: id)
		}
		timeline.gaps[id]?.error = nil
		timeline.gaps[id]?.isLoading = true
		timeline.updateElements()
		gapTasks[gap.id] = Task {
			defer {
				gapTasks.removeValue(forKey: gap.id)
			}
			
			do {
				for service in services {
					let serviceTimeline = service.timeline(within: gap.range, gapID: gap.id, isolation: #isolation)
					
					for try await fragment in serviceTimeline {
						try Task.checkCancellation()
						try timeline.update(with: fragment)
					}
				}
			} catch let error as Gap.Error {
				timeline.gaps[gap.id]?.error = error
			} catch {
				print(error.localizedDescription)
			}
			
			timeline.gaps[gap.id]?.isLoading = false
			timeline.updateElements()
			
			print("Timeline: \(timeline.elements.count)")
		}
	}
	

	func updateAccounts(_ accounts: [UserAccount]) {
		services = accounts
			.map { (account) -> any SocialAccount in
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
}

