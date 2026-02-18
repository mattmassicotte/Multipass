//
//  RangeDate+extensions.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-02-03.
//

import Foundation

extension Range<Date> {
	/// Removes a date range from another date range.
	/// - Parameter other: Range to remove
	/// - Returns: A tuple containing 0 to 2 ranges that remain.
	func removing(_ other: Self, calendar: Calendar = .current, granularity: Calendar.Component = .second) -> (before: Self?, after: Self?) {
		if other.isEmpty { return (before: self, after: nil) }
		
		if calendar.isDate(other.lowerBound, equalTo: lowerBound,  toGranularity: granularity)
			|| other.lowerBound < lowerBound {
			if calendar.isDate(other.upperBound, equalTo: upperBound,  toGranularity: granularity)
				|| other.upperBound > upperBound {
				return (before: nil, after: nil)
			}
			return (
				before: lowerBound..<Swift.min(upperBound, other.upperBound),
				after: nil
			)
		}
		
		if calendar.isDate(other.upperBound, equalTo: upperBound,  toGranularity: granularity)
			|| other.upperBound > upperBound {
			if calendar.isDate(other.lowerBound, equalTo: lowerBound,  toGranularity: granularity)
				|| other.lowerBound < lowerBound {
				return (before: nil, after: nil)
			}
			return (
				before: nil,
				after: Swift.max(lowerBound, other.lowerBound)..<upperBound
			)
		}
		
		return (
			before: lowerBound..<other.lowerBound,
			after: other.upperBound..<upperBound
		)
	}
	
	/// Trims the upper bound to a specific date shrinking the range if the date is less than the current upper bound.
	mutating func trimUpperBound(to date: Date) {
		self = lowerBound..<Swift.max(lowerBound, Swift.min(date, upperBound))
	}
	
	func adding(_ other: Self) -> [Self] {
		if self.connected(to: other) {
			[Swift.min(lowerBound, other.lowerBound)..<Swift.max(upperBound, other.upperBound)]
		} else {
			[self, other]
		}
	}
	
	/// Compares two date ranges to see if they overlap or are connected within a certain threshold.
	/// - Parameters:
	///   - other: Date range to check against.
	///   - calendar: Calendar to use when comparing dates.
	///   - granularity: Allowable distance between two date ranges to be considered connected.
	/// - Returns: True when two date ranges overlap or are connected end to end.
	func connected(to other: Self, calendar: Calendar = .current, granularity: Calendar.Component = .second) -> Bool {
		overlaps(other)
		|| calendar.isDate(upperBound, equalTo: other.lowerBound, toGranularity: granularity)
		|| calendar.isDate(lowerBound, equalTo: other.upperBound, toGranularity: granularity)
	}
	
	func isEqual(to other: Self, calendar: Calendar = .current, toGranularity component: Calendar.Component = .second) -> Bool {
		calendar.isDate(lowerBound, equalTo: other.lowerBound, toGranularity: component)
		&& calendar.isDate(upperBound, equalTo: other.upperBound, toGranularity: component)
	}
	
	func contains(_ other: Self, calendar: Calendar = .current, toGranularity component: Calendar.Component = .second) -> Bool {
		contains(other.lowerBound) && (
			contains(other.upperBound)
			|| calendar.isDate(upperBound, equalTo: other.upperBound, toGranularity: component)
		)
	}
	
	static func / (lhs: Self, rhs: Self) -> Double {
		lhs.upperBound.timeIntervalSince(lhs.lowerBound) / rhs.upperBound.timeIntervalSince(rhs.lowerBound)
	}
}

extension Range<Date>? {
	/// Creates a date range that is the result of and AND operation between two date ranges.
	func and(_ other: Range<Date>) -> Range<Date>? {
		guard
			let self = self,
			self.connected(to: other)
		else { return nil }
		return Swift.max(self.lowerBound, other.lowerBound)..<Swift.min(self.upperBound, other.upperBound)
	}
}

extension Array<Range<Date>> {
	/// Removed a range from an array of sorted ranges.
	/// - Parameter range: Range to me removed.
	/// - Returns: An array of date ranges that may be smaller or larger than the original depending on what parts have been filled.
	func removing(_ range: Range<Date>) -> Self {
		reduce(into: Self()) { partialResult, gap in
			let (before, after) = gap.removing(range)
			partialResult += [before, after].compactMap { $0 }
		}
	}
	
	/// Creates a date range that is the result of and AND operation between all date ranges.
	func and() -> Range<Date>? {
		dropFirst()
			.reduce(into: self.first) { partialResult, range in
				partialResult = partialResult.and(range)
			}
	}
	
	/// Merges a new date range then sorts and combines any overlapping date ranges.
	func merging(_ other: Range<Date>) -> Self {
		let sorted = (self + [other])
			.sorted {
				(
					$0.lowerBound,
					$0.upperBound
				) < (
					$1.lowerBound,
					$1.upperBound
				)
			}
		
		let reduced = sorted
			.reduce(into: Self()) { partialResult, range in
				if let previous = partialResult.last,
				   previous.connected(to: range) {
					partialResult.removeLast(1)
					partialResult.append(Swift.min(previous.lowerBound, range.lowerBound)..<Swift.max(previous.upperBound, range.upperBound))
				} else {
					partialResult.append(range)
				}
			}
		
		return reduced
	}
}
