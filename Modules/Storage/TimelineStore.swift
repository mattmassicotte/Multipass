import SwiftUI

import Empire
import Utility

@IndexKeyRecord("singleKey")
public struct ServicePosition: Hashable, Sendable {
	public var singleKey: String = "me"
	public var date: Date
	public var bluesky: String?
	public var mastodon: String?
	
	public init(date: Date, bluesky: String?, mastodon: String?) {
		self.date = date
		self.bluesky = bluesky
		self.mastodon = mastodon
	}
	
	public static let unknown = ServicePosition(date: .now, bluesky: nil, mastodon: nil)
}

@MainActor
@Observable
public final class TimelineStore {
	public var maximumPosts: Int = 100
	
	@ObservationIgnored
	private let store: Store?
	
	public init() {
		let url = URL
			.cachesDirectory
			.appending(path: "timeline")
		
		print("timeline store url: ", url)
		
		do {
			try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
			
			let database = try Database(url: url)
			self.store = Store(database: database)
		} catch {
			self.store = nil
			print("unable to initialize store:", error)
		}
	}
	
	public var position: ServicePosition? {
		get {
			try! store?.select(key: Tuple("me"))
		}
		set {
			if let value = newValue {
				try! store?.insert(value)
				return
			}
			
			try! store?.withTransaction { ctx in
				try ServicePosition.delete(in: ctx, singleKey: "me")
			}
		}
	}
}
