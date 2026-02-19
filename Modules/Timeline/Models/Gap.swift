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
	private(set) var loadedRanges: LoadedRanges
	/// True if there is a current loading task running for this gap
	public var isLoading: Bool
	
	/// Should loaded ranges of posts be shown or hidden by this gap. Only ranges anchored at the start and end loaded by all accounts listed in `serviceIDs` will be revealed.
	public let showLoadedRanges: Bool = false
	/// Read/Unread status of posts in this gap
	public var readStatus: ReadStatus
	/// Error status of this gap
	public var error: Self.Error? = nil
	
	init(
		id: UUID,
		range: Range<Date>,
		serviceIDs: Set<SocialServiceID>,
		loadedRanges: LoadedRanges = [:],
		isLoading: Bool = false,
		readStatus: ReadStatus = .unknown
	) {
		self.id = id
		self.range = range
		self.serviceIDs = serviceIDs
		self.loadedRanges = loadedRanges
		self.isLoading = isLoading
		self.readStatus = readStatus
	}
	
	public enum LoadingStatus: String, Hashable, Sendable, CaseIterable {
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
	
	enum Action {
		case fill(Gap.ID)
		case cancel(Gap.ID)
		case reveal(
			gapID: Gap.ID,
			fromEdge: TemporalEdge,
			toDate: Date? = nil,
			anchor: TemporalEdge
		)
		
		var gapID: Gap.ID {
			switch self {
			case let .fill(id): id
			case let .cancel(id): id
			case let .reveal(id, _, _, _): id
			}
		}
	}
	
	public enum Error: LocalizedError, Hashable, Sendable {
		case noSocialServiceMatching(id: SocialServiceID)
		case noGapMatching(id: Gap.ID)
		case gapAlreadyExists(id: Gap.ID)
		case unloadedGapCannotBeRemoved(id: Gap.ID)
		case gapAlreadyBeingFilled(id: Gap.ID)
		
		public var errorDescription: String? {
			switch self {
			case let .noSocialServiceMatching(id):
				"No social service available matching the provided ID: \(id)"
			case let .noGapMatching(id):
				"No gap available matching the provided ID: \(id)"
			case let .gapAlreadyExists(id):
				"Gap with the same id already exists. ID: \(id)"
			case let .unloadedGapCannotBeRemoved(id):
				"Unloaded gap cannot be removed. ID: \(id)"
			case let .gapAlreadyBeingFilled(id):
				"Gap already being filled. ID: \(id)"
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
	/// Loading status of the posts in this gap.
	var loadingStatus: LoadingStatus {
		if error != nil {
			return .error
		} else if unloadedRange == nil {
			return .loaded
		} else if isLoading {
			return .loading
		} else if loadedRanges.isEmpty {
			return .unloaded
		} else {
			return .paused
		}
	}
	
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
			
		return max(range.lowerBound, min(lowerBound, range.upperBound))..<range.upperBound
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
			
		return range.lowerBound..<max(range.lowerBound, min(upperBound, range.upperBound))
	}
	
	var loadedNewestProgress: Double {
		min(loadedNewestRange / range, 1)
	}
	
	var loadedOldestProgress: Double {
		min(loadedOldestRange / range, 1)
	}
	
	var loadedProgress: Double {
		unloadedRange == nil ? 1 : min(loadedNewestProgress + loadedOldestProgress, 1)
	}
	
	mutating func fill(with fragment: TimelineFragment) throws {
		isLoading = true
		
		guard serviceIDs.contains(fragment.serviceID) else {
			throw Error.noSocialServiceMatching(id: fragment.serviceID)
		}
		
		let serviceRanges = loadedRanges[fragment.serviceID] ?? []
		
		loadedRanges[fragment.serviceID] = serviceRanges.merging(fragment.range)
		
		if unloadedRange == nil {
			/// End loading
			isLoading = false
		} else if let concealedRange, range != concealedRange {
			/// Show posts automatically
			range = concealedRange
		}
	}
	
	func overlaps(_ other: Gap) -> Bool {
		range.overlaps(other.range)
	}
	
	func removing(_ other: Range<Date>) -> (before: Self?, after: Self?) {
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
			let newGap = Gap(id: UUID(), range: afterRange, serviceIDs: serviceIDs)
			return (before: updatedGap, after: newGap)
		}
	}
	
	static func example(
		id: UUID = UUID(),
		range: Range<Date> = (Date().addingTimeInterval(.hours(-2)))..<Date(),
		serviceIDs: Set<SocialServiceID> = [],
		loadedRanges: LoadedRanges = [:],
		isLoading: Bool = false,
		readStatus: ReadStatus = .unknown,
		error: Error? = nil
	) -> Self {
		var gap = Self.init(
			id: id,
			range: range,
			serviceIDs: serviceIDs,
			loadedRanges: loadedRanges,
			isLoading: isLoading,
			readStatus: readStatus
		)
		
		gap.error = error
		
		return gap
	}
}

public extension [Gap] {
	/// Inserts a new gap into an array adjusting others accordingly
	mutating func insertNewGap(range: Range<Date>, serviceIDs: Set<SocialServiceID>) -> Gap.ID {
		let newGap = Gap(id: UUID(), range: range, serviceIDs: serviceIDs)
		let adjustedGaps: [Gap] = reduce(into: [Gap]()) { partialResult, gap in
			if gap.overlaps(newGap) {
				let remaining = gap.removing(newGap.range)
				partialResult += [remaining.before, remaining.after].compactMap { $0 }
			} else {
				partialResult.append(gap)
			}
		}
			
		self = (adjustedGaps + [newGap]).sorted()
		return newGap.id
	}
	
	
	mutating func fill(with fragment: TimelineFragment) throws {
		try self[fragment.gapID]?.fill(with: fragment)
	}
}


