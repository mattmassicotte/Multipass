import SwiftUI

import OAuthenticator
import Valet
import Utility
import MastodonAPI
import BlueskyAPI

struct ContentView: View {
	var body: some View {
		VStack {
			Button("Do The Thing") {
				Task<Void, Never> {
					do {
						try await doOtherThing()
					} catch {
						print("hmmm", error)
					}
				}
			}
		}
		.padding()
	}
	
	private func doThing() async throws {
		let params = Mastodon.UserTokenParameters(
			host: "mastodon.social",
			clientName: "Multipass",
			redirectURI: "MultipassApp://mastodon/oauth",
			scopes: ["read", "write", "follow", "push"]
		)
		
		let responseProvider = URLSession.defaultProvider
//			let registrationData = try await Mastodon.register(with: params, urlLoader: responseProvider)
//			
//			guard let redirectURI = registrationData.redirectURI, let callbackURL = URL(string: redirectURI) else {
//				throw AuthenticatorError.missingRedirectURI
//			}
//
//			
//			let appCreds = AppCredentials(
//				clientId: registrationData.clientID,
//				clientPassword: registrationData.clientSecret,
//				scopes: params.scopes,
//				callbackURL: callbackURL
//			)
			
		let bundleId = Bundle.main.bundleIdentifier!
		let groupId = SharedGroupIdentifier(appIDPrefix: MTPAppIdentifierPrefix, nonEmptyGroup: bundleId)!
		let valet = Valet.sharedGroupValet(with: groupId, accessibility: .whenUnlocked)
		
		let storage = LoginStorage {
			do {
				let data = try valet.object(forKey: "Mastodon OAuth")
				
				let login = try JSONDecoder().decode(Login.self, from: data)
				
				print("retrieving:", login)
				
				return login
			} catch KeychainError.itemNotFound {
				print("oauth tokens not in the keychain")
			}
			
			return nil
		} storeLogin: { login in
			print("storing:", login)
			
			let data = try JSONEncoder().encode(login)
			
			try valet.setObject(data, forKey: "Mastodon OAuth")
		}
		
		let config = Authenticator.Configuration(
			appCredentials: appCreds,
			loginStorage: storage,
			tokenHandling: Mastodon.tokenHandling(with: params)
		)
		
		let authenticator = Authenticator(config: config, urlLoader: responseProvider)
		
		let client = MastodonAPI.Client(host: params.host, provider: authenticator.responseProvider)
		
		let statusArray = try await client.timeline()
		
		for status in statusArray {
			print(status.id, status.account.username, status.content)
		}
	}
	
	struct BlueskyLoginCredentials: Codable {
		let userName: String
		let password: String
	}
	
	private func doOtherThing() async throws {
		let responseProvider = URLSession.defaultProvider
		
		let bundleId = Bundle.main.bundleIdentifier!
		let groupId = SharedGroupIdentifier(appIDPrefix: MTPAppIdentifierPrefix, nonEmptyGroup: bundleId)!
		let valet = Valet.sharedGroupValet(with: groupId, accessibility: .whenUnlocked)
		
		let data = try valet.object(forKey: "Bluesky Auth")
		let login = try JSONDecoder().decode(BlueskyAPI.Credentials.self, from: data)
		
		let client = BlueskyAPI.Client(
			host: "bsky.social",
			handle: login.identifier,
			appPassword: login.password,
			provider: responseProvider
		)
		
		
		let response = try await client.createSession(with: login)
		
		let timeline = try await client.timeline(token: response.accessJwt)
		
		for post in timeline.feed {
			print(post)
		}
	}
}

#Preview {
	ContentView()
}
