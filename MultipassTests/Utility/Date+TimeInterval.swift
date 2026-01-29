import Foundation

extension Date {
	init(_ interval: TimeInterval) {
		self.init(timeIntervalSince1970: interval)
	}
}
