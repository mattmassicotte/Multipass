import CompositeSocialService
import SocialModels
import Utility

enum AuthorResolverError: Error {
	case noServiceForPlatform(SocialPlatform)
	case unexpectedGitHubResponse
}

public final class ProfileStore {
	let accounts: SocialAccounts
	private var profileCache: [String: Profile] = [:]
	private var compositeProfiles: [Handle: CompositeProfile] = [:]
	let githubClient: GitHubSocialClient

	public init(accounts: SocialAccounts, provider: @escaping URLResponseProvider) {
		self.accounts = accounts
		self.githubClient = GitHubSocialClient(provider: provider)
	}

	public func prefetch(authors: [Author]) async throws {
		var byPlatform: [SocialPlatform: Set<String>] = [:]

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

	private func prefetch(profiles ids: Set<String>, for platform: SocialPlatform) async throws {
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

	private func profile(for id: String, on platform: SocialPlatform) async throws -> Profile {
		guard let service = self.accounts.service(for: platform) else {
			throw AuthorResolverError.noServiceForPlatform(platform)
		}

		// intentionally racy, I'm being lazy right now
		if let profile = profileCache[id] {
			return profile
		}

		let profile = try await service.profile(for: id)

		self.profileCache[id] = profile

		return profile
	}

	public func compositeProfile(for author: Author) async throws -> CompositeProfile {
		if let profile = self.compositeProfiles[author.handle] {
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
			self.compositeProfiles[handle] = composite
		}

		if handles.count > 1 {
			print("hey!", handles)
		}

		return composite
	}
}
