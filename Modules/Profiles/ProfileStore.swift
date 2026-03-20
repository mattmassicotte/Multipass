import SocialClients
import SocialModels
import Utility

enum AuthorResolverError: Error {
	case noServiceForPlatform(SocialService)
	case unexpectedGitHubResponse
}

public final class ProfileStore {
	public var accounts: SocialAccounts
	private var profileCache: Cache<String, Profile>
	private var compositeProfileCache: Cache<Handle, CompositeProfile>
	let githubClient: GitHubSocialClient

	public init(accounts: SocialAccounts, provider: @escaping URLResponseProvider) {
		self.accounts = accounts
		self.githubClient = GitHubSocialClient(provider: provider)

		self.profileCache = Cache(cachePath: "profiles")
		self.compositeProfileCache = Cache()
	}

	public func prefetch(authors: [Author]) async throws {
		var byPlatform: [SocialService: Set<String>] = [:]

		for author in authors {
			var set = byPlatform[author.handle.platform] ?? Set()

			set.insert(author.platformId)

			byPlatform[author.handle.platform] = set
		}

		for (platform, ids) in byPlatform {
			try await prefetch(profiles: ids, for: platform)
		}

		for author in authors {
			let _ = try await compositeProfile(for: author)
		}
	}

	private func prefetch(profiles ids: Set<String>, for platform: SocialService) async throws {
		guard let account = self.accounts.service(for: platform) else {
			throw AuthorResolverError.noServiceForPlatform(platform)
		}

		let neededIds = ids.filter({ profileCache[$0] == nil })

		let profiles = try await account.profiles(for: Array(neededIds))

		for profile in profiles {
			self.profileCache[profile.platformId] = profile
		}
	}

	private func knownHandles(for profile: Profile) async throws -> [Handle] {
		let githubProfiles = try await githubClient.socialProfiles(for: profile)

		return githubProfiles.compactMap { $0.handle }
	}

	private func profile(for id: String, on platform: SocialService) async throws -> Profile {
		guard let service = self.accounts.service(for: platform) else {
			throw AuthorResolverError.noServiceForPlatform(platform)
		}

		return try await profileCache.readOrFill(id) {
			try await service.profile(for: id)
		}
	}

	public func compositeProfile(for author: Author) async throws -> CompositeProfile {
		if let profile = self.compositeProfileCache[author.handle] {
			print("profile cache hit:", author.handle)
			return profile
		}

		// we cannot get information about bluesky accounts
		if author.handle.platform == .bluesky {
			return CompositeProfile(author: author)
		}

		// intentionally racy, I'm being lazy right now
		let profile = try await profile(for: author.platformId, on: author.handle.platform)
		let knownHandles = try await knownHandles(for: profile)
		let handles = Set(knownHandles + [author.handle])

		let composite = CompositeProfile(
			name: author.name,
			handles: handles,
			avatarURL: author.avatarURL
		)

		for handle in handles {
			compositeProfileCache.write(handle, composite)
		}

		if handles.count > 1 {
			print("hey!", handles)
		}

		return composite
	}
}
