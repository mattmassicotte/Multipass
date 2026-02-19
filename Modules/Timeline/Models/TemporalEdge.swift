//
//  TemporalEdge.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-02-18.
//

import Foundation

public enum TemporalEdge: Hashable, Sendable {
	/// The oldest date
	case oldest
	/// The newest Date
	case newest
}

extension Range<Date> {
	func removing(from edge: TemporalEdge, to date: Date) -> Self? {
		switch edge {
		case .oldest:
			guard date < upperBound else { return nil }
			return Swift.max(lowerBound, date)..<upperBound
		case .newest:
			guard date > lowerBound else { return nil }
			return lowerBound..<Swift.min(upperBound, date)
		}
	}
}
