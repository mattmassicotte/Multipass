//
//  Gap.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-02-02.
//

import CompositeSocialService
import Foundation

public struct Gap: Hashable, Sendable, Identifiable {
	public typealias LoadedRanges = [SocialServiceID : Array<Range<Date>>]
	
	/// Unique ID created when gap is initialized
	public let id: UUID
	/// A date range that defines the bounds of this gap
	public var range: Range<Date>
	/// Service IDs
	public let serviceIDs: Set<SocialServiceID>
	/// A dictionary of arrays of service  keyed to the service ID string.
	public var loadedRanges: LoadedRanges
	/// Loading status of the posts in this gap.
	public var loadingStatus: LoadingStatus
	/// Should loaded ranges of posts be shown or hidden by this gap. Only ranges anchored at the start and end loaded by all accounts listed in `serviceIDs` will be revealed.
	public var showLoadedRanges: Bool = false
	/// Read/Unread status of posts in this gap
	public var readStatus: ReadStatus
	
	init(
		id: UUID,
		range: Range<Date>,
		serviceIDs: Set<SocialServiceID>,
		loadedRanges: LoadedRanges = [:],
		loadingStatus: LoadingStatus,
		readStatus: ReadStatus = .unknown
	) {
		self.id = id
		self.range = range
		self.serviceIDs = serviceIDs
		self.loadedRanges = loadedRanges
		self.loadingStatus = loadingStatus
		self.readStatus = readStatus
	}
	
	public enum LoadingStatus: String, Hashable, Sendable {
		case unloaded
		case loading
		case paused
		case loaded
		case error
	}
	
	public enum ReadStatus: Hashable, Sendable {
		case unknown
		case read
	}
	
	public enum OpeningDirection {
		/// Opening direction that locks to the oldest post so the user can read posts chronologically
		case oldestFirst
		/// Opening direction that locks to the newest post so the user can read posts chronologically
		case newestFirst
	}
	
	public enum Error: LocalizedError {
		case noServiceMatchingID(_ id: SocialServiceID)
		case noGapMatchingID(id: Gap.ID)
		
		public var errorDescription: String? {
			switch self {
			case .noGapMatchingID:
				"No gap available matching the provided ID."
			case .noServiceMatchingID(_):
				"No social service available matching the provided ID."
			}
		}
	}
}

extension Gap: Comparable {
	var sortValue: (Date, Date, UUID) {
		/// Sorting by newest date first.
		(range.lowerBound, range.upperBound, id)
	}
	
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.sortValue < rhs.sortValue
	}
}

public extension Gap {
	/// Range of posts to be concealed
	var concealedRange: Range<Date>? {
		showLoadedRanges ? unloadedRange : range
	}
	
	func conceals(_ date: Date) -> Bool {
		concealedRange?.contains(date) ?? false
	}
	
	/// Range trimming the edges where posts have been loaded from all services.
	var unloadedRange: Range<Date>? {
		let lowerBound = loadedOldestRange.upperBound
		let upperBound = loadedNewestRange.lowerBound
		
		if lowerBound <= upperBound {
			return lowerBound..<upperBound
		} else {
			return nil
		}
	}
	
	/// Largest date range anchored at the upper bound without gaps that holds posts from every service.
	var loadedNewestRange: Range<Date> {
		/// An array of the newest range from each service that extends to the upper bound of the gap range.
		let lastRanges = serviceIDs
			.compactMap { loadedRanges[$0]?.last }
			.filter {
				Calendar.current.isDate($0.upperBound, equalTo: range.upperBound, toGranularity: .second)
			}
		
		guard
			lastRanges.count == serviceIDs.count,
			let lowerBound = lastRanges.map(\.lowerBound).max()
		else {
			return range.upperBound..<range.upperBound
		}
			
		return lowerBound..<range.upperBound
	}
	
	/// Largest date range anchored at the lower bound without gaps that holds posts from every service.
	var loadedOldestRange: Range<Date> {
		/// An array of the newest range from each service that extends to the upper bound of the gap range.
		let firstRanges = serviceIDs
			.compactMap { loadedRanges[$0]?.first }
			.filter {
				Calendar.current.isDate($0.lowerBound, equalTo: range.lowerBound, toGranularity: .second)
			}
		
		guard
			firstRanges.count == serviceIDs.count,
			let upperBound = firstRanges.map(\.upperBound).min()
		else {
			return range.lowerBound..<range.lowerBound
		}
			
		return range.lowerBound..<upperBound
	}
	
	mutating func updateRanges(with fragment: TimelineFragment) throws {
		loadingStatus = .loading
		
		guard serviceIDs.contains(fragment.serviceID) else {
			throw Error.noServiceMatchingID(fragment.serviceID)
		}
		
		let serviceRanges = loadedRanges[fragment.serviceID] ?? []
		
		loadedRanges[fragment.serviceID] = serviceRanges.merging(fragment.range)
		
		if let concealedRange, range != concealedRange {
			range = concealedRange
		} else {
			loadingStatus = .loaded
		}
	}
	
	func overlaps(_ other: Gap) -> Bool {
		range.overlaps(other.range)
	}
	
	
	func removing(_ other: Range<Date>) -> (before: Self?, after: Self?) {
		if loadingStatus == .loading {
			/// Maybe throw an error here
		}
		
		var updatedGap = self
		
		switch range.removing(other) {
		case (nil, nil):
			return (before: nil, after: nil)
		case let (.some(newRange), nil):
			updatedGap.range = newRange
			return (before: updatedGap, after: nil)
		case let (nil, .some(newRange)):
			updatedGap.range = newRange
			return (before: nil, after: updatedGap)
		case let (.some(beforeRange), .some(afterRange)):
			updatedGap.range = beforeRange
			let newGap = Gap(id: UUID(), range: afterRange, serviceIDs: serviceIDs, loadingStatus: .unloaded)
			return (before: updatedGap, after: newGap)
		}
	}
	
	static func example(
		id: UUID = UUID(),
		range: Range<Date>,
		serviceIDs: Set<SocialServiceID> = [],
		loadedRanges: LoadedRanges = [:],
		loadingStatus: LoadingStatus = .unloaded,
		readStatus: ReadStatus = .unknown
	) -> Self {
		.init(
			id: id,
			range: range,
			serviceIDs: serviceIDs,
			loadedRanges: loadedRanges,
			loadingStatus: loadingStatus,
			readStatus: readStatus
		)
	}
}

public extension [Gap] {
	/// Inserts a new gap into an array adjusting others accordingly
	mutating func insert(_ newGap: Gap) {
		let adjustedGaps: [Gap] = reduce(into: [Gap]()) { partialResult, gap in
			if gap.overlaps(newGap) {
				let remaining = gap.removing(newGap.range)
				partialResult += [remaining.before, remaining.after].compactMap { $0 }
			} else {
				partialResult.append(gap)
			}
		}
			
		self = (adjustedGaps + [newGap]).sorted()
	}
}


