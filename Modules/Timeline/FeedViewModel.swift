import SwiftUI

import CompositeSocialService
import Storage
import StableView

@MainActor
@Observable
final class FeedViewModel {
	@ObservationIgnored
	private var client: CompositeClient
	@ObservationIgnored
	private var services: [any SocialService] = []
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
//				let handle = (pos.item.repostingAuthor ?? pos.item.author)?.handle
//				
//				print("position:", handle, pos.offset)
				updateServicePosition(for: pos.item)
			}
		}
	}
	
	private(set) var posts: [Post] = []

	init(secretStore: SecretStore, timelineStore: TimelineStore) {
		self.secretStore = secretStore
		self.timelineStore = timelineStore
		self.client = CompositeClient(
			secretStore: secretStore,
			services: []
		)
		
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
		guard
			let pos = positionAnchor,
			let idx = posts.firstIndex(of: pos.item)
		else {
			return -1
		}
		
		return idx
	}
	
	func refresh() async {
		if client.services.isEmpty {
			return
		}
		
		let position = servicePosition ?? .unknown
		print("refreshing from:", position)
		
		do {
			let newPosts = try await client.timeline(from: position, newer: true)
			
			mergeNewPosts(newPosts)
		} catch {
			print("dammm", error)
		}
	}
	
	private func mergeNewPosts(_ newPosts: [Post]) {
		var currentPosts = posts
		
		// filter out duplicates
		let currentIds = Set(currentPosts.map { $0.id })
		let newPosts = newPosts.filter({ currentIds.contains($0.id) == false })
		
		let currentCount = currentPosts.count
		let removeCount = (currentCount + newPosts.count) - timelineStore.maximumPosts
		
		
		if removeCount > 0 {
			currentPosts.removeLast(min(removeCount, currentCount))
		}
		
		currentPosts.append(contentsOf: newPosts)
		currentPosts.sort(by: { $0 > $1 })
		
		self.posts = currentPosts
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
		
		self.client = CompositeClient(secretStore: secretStore, services: services)
		self.accountsIdentifier = accounts.hashValue
	}
	
	func handlePostAction(action: PostStatusAction, post: Post) {
		switch action {
		case .like:
			Task {
				try! await self.client.likePost(post)
			}
		case .repost:
			print("nope, not yet")
		}
		
	}
}
