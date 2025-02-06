import SwiftUI

/// This might need to be further customized at some point
public struct UserAccountDetails: Codable, Hashable, Sendable {
	public var host: String
	public var user: String

	public init(host: String, user: String) {
		self.host = host
		self.user = user
	}
}

public struct UserAccount: Codable, Sendable, Hashable {
	public var source: DataSource
	public var details: UserAccountDetails

	public init(source: DataSource, details: UserAccountDetails) {
		self.source = source
		self.details = details
	}
}

extension UserAccount: Identifiable {
	public var id: String {
		"\(source):\(details.host):\(details.user)"
	}
}

@MainActor
@Observable
public final class UserAccountStore {
	private static let accountsKey = "Accounts"
	
	public private(set) var accounts: [UserAccount]

	@ObservationIgnored
	private let responseProvider = URLSession.defaultProvider
	@ObservationIgnored
	private let secretStore: SecretStore

	public init(secretStore: SecretStore) {
		self.secretStore = secretStore
		self.accounts = []
		
		Task<Void, Never> {
			do {
				guard let data = try await secretStore.read(Self.accountsKey) else {
					self.accounts = []
					return
				}
				
				self.accounts = try JSONDecoder().decode([UserAccount].self, from: data)
			} catch {
				print("failed to decode accounts:", error)
				
				self.accounts = []
			}
		}
	}

	public func addAccount(_ account: UserAccount) async throws {
		self.accounts.append(account)
		
		let data = try JSONEncoder().encode(accounts)
		try await secretStore.write(data, Self.accountsKey)
	}
	
	public func removeAllAccounts() async throws {
		self.accounts.removeAll()
		
		let data = try JSONEncoder().encode(accounts)
		try await secretStore.write(data, Self.accountsKey)
	}
}
