import Foundation

import CompositeSocialService
import Utility
import Valet

extension Valet {
	static func mainApp() -> Valet {
		let bundleId = Bundle.main.bundleIdentifier!
		let groupId = SharedGroupIdentifier(appIDPrefix: MTPAppIdentifierPrefix, nonEmptyGroup: bundleId)!
		
		return Valet.sharedGroupValet(with: groupId, accessibility: .whenUnlocked)
	}
}

extension SecretStore {
	static func valetStore(using valet: Valet) -> SecretStore {
		SecretStore(
			read: {
				do {
					return try valet.object(forKey: $0)
				} catch KeychainError.itemNotFound {
					return nil
				}
			},
			write: {
				try valet.setObject($0, forKey: $1)
			}
		)
	}
}
