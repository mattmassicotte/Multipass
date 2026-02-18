//
//  Array+extensions.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-02-17.
//

import Foundation

extension Array {
	func firstAfter(_ predicate: (Element) -> Bool) -> Element? {
		guard let matchIndex = firstIndex(where: predicate),
			  matchIndex < index(before: endIndex) else {
			return nil
		}
		return self[index(after: matchIndex)]
	}
	
	func lastBefore(_ predicate: (Element) -> Bool) -> Element? {
		guard let matchIndex = firstIndex(where: predicate),
			  matchIndex > startIndex else {
			return nil
		}
		return self[index(before: matchIndex)]
	}
}

extension Array where Element: Identifiable {
	subscript(id: Element.ID) -> Element? {
		get {
			first { $0.id == id }
		}
		set {
			guard
				let index = firstIndex(where: { $0.id == id }),
				let newValue
			else { return }
			self[index] = newValue
		}
	}
	
	func firstAfter(id: Element.ID) -> Element? {
		firstAfter { $0.id == id }
	}
	
	func lastBefore(id: Element.ID) -> Element? {
		lastBefore { $0.id == id }
	}
}


