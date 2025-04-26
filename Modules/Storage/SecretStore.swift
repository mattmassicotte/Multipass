import Foundation

public struct SecretStore: Sendable {
	public typealias ReadSecret = @Sendable (String) async throws -> Data?
	public typealias WriteSecret = @Sendable (Data, String) async throws -> Void

	public let read: ReadSecret
	public let write: WriteSecret

	public init(read: @escaping ReadSecret, write: @escaping WriteSecret) {
		self.read = read
		self.write = write
	}
}
