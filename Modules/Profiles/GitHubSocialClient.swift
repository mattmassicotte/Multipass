import Foundation

import SocialClients
import SocialModels

struct GithubSocialProfile: Sendable, Codable {
	let provider: String
	let url: String

	var urlValue: URL? {
		URL(string: url)
	}

	var handle: Handle? {
		guard
			let url = urlValue,
			let host = url.host()
		else {
			return nil
		}

		switch provider {
		case "mastodon":
			return Handle(host: host, name: String(url.lastPathComponent.dropFirst()), service: .mastodon)
		case "bluesky":
			return Handle(host: host, name: url.lastPathComponent, service: .bluesky)
		default:
			return nil
		}
	}
}

extension GithubSocialProfile: CustomDebugStringConvertible {
	var debugDescription: String {
		"<\(provider): \(url) \(handle.debugDescription)>"
	}
}

final class GitHubSocialClient {
	let provider: URLResponseProvider

	init(provider: @escaping URLResponseProvider) {
		self.provider = provider
	}

	public func socialProfiles(for profile: Profile) async throws -> [GithubSocialProfile] {
		let githubProfiles = profile.githubProfiles

		guard
			let username = githubProfiles.first,
			githubProfiles.count == 1
		else {
			return []
		}

		return try await socialProfiles(for: username)
	}

	public func socialProfiles(for username: String) async throws -> [GithubSocialProfile] {
		guard let url = URL(string: "https://api.github.com/users/\(username)/social_accounts") else {
			fatalError()
		}

		var request = URLRequest(url: url)

		request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
		request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

		let (data, response) = try await provider(request)

		guard
			let httpResponse = response as? HTTPURLResponse,
			httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
		else {
			print("unexpected data:", String(decoding: data, as: UTF8.self))
			print("response:", response)

			throw AuthorResolverError.unexpectedGitHubResponse
		}

		return try JSONDecoder().decode([GithubSocialProfile].self, from: data)
	}
}
