import Foundation

import SocialModels

public struct ServiceAccount: Sendable {
	public let source: SocialService
	public let handle: String
	public let displayName: String
	public let url: String
	public let avatarURL: URL
	public let headerURL: URL
}

public struct Account: Sendable {
	public let serviceAccounts: [ServiceAccount]
}

@MainActor
@Observable
public final class AccountStore {
}
