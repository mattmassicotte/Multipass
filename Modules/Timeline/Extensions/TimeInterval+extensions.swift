//
//  TimeInterval+extensions.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-02-18.
//

import Foundation

public extension TimeInterval {
	static func minutes(_ count: Double) -> Self {
		60 * count
	}
	
	static func hours(_ count: Double) -> Self {
		60 * 60 * count
	}
	
	static func days(_ count: Double) -> Self {
		24 * 60 * 60 * count
	}
	
	static func minutes(_ count: Int) -> Self {
		minutes(Double(count))
	}
	
	static func hours(_ count: Int) -> Self {
		hours(Double(count))
	}
	
	static func days(_ count: Int) -> Self {
		days(Double(count))
	}
}

public extension Duration {
	static func minutes(_ count: Double) -> Self {
		seconds(60) * count
	}
	
	static func hours(_ count: Double) -> Self {
		minutes(60) * count
	}
	
	static func days(_ count: Double) -> Self {
		hours(24) * count
	}
	
	static func minutes(_ count: Int) -> Self {
		minutes(Double(count))
	}
	
	static func hours(_ count: Int) -> Self {
		hours(Double(count))
	}
	
	static func days(_ count: Int) -> Self {
		days(Double(count))
	}
}
