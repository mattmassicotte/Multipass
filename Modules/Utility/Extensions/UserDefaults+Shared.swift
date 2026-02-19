import Foundation

extension UserDefaults {
	public static var sharedSuite: UserDefaults? {
		UserDefaults(suiteName: MTPAppGroupIdentifier)
	}
}

extension FileManager {
	public var appGroupURL: URL? {
		containerURL(forSecurityApplicationGroupIdentifier: MTPAppGroupIdentifier)
	}
}
