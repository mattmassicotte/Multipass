//
//  TimelineFragment.swift
//  CompositeSocialService
//
//  Created by Ryan Lintott on 2026-02-06.
//

import Foundation

public struct TimelineFragment: Hashable, Sendable {
	/// ID of the service used to fetch this fragment
	public let serviceID: SocialAccountID
	/// ID for the gap used to fetch this fragment
	public let gapID: UUID
	/// Posts sorted in order from newest to oldest.
	public let posts: [Post]
	/// Date range used to download posts. May extend beyond lower and upper bounds of post dates.
	public let range: Range<Date>
}

extension TimelineFragment: Comparable {
	var sortValue: (Date, Date, SocialAccountID, UUID) {
		(range.upperBound, range.lowerBound, serviceID, gapID)
	}
	
	public static func < (lhs: Self, rhs: Self) -> Bool {
		/// Sorting by newest date first.
		lhs.sortValue < rhs.sortValue
	}
}
