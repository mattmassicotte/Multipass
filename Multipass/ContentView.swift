import SwiftUI

import OAuthenticator
import Valet
import Utility

struct ContentView: View {
	var body: some View {
		VStack {
			Button("Do The Thing") {
				Task {
					await doThing()
				}
			}
		}
		.padding()
	}
	
	func doThing() async {
		let params = Mastodon.UserTokenParameters(
			host: "mastodon.social",
			clientName: "Multipass",
			redirectURI: "MultipassApp://mastodon/oauth",
			scopes: ["read", "write", "follow", "push"]
		)
		
		do {
//			let responseProvider = URLSession.defaultProvider
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

			let authenticator = Authenticator(config: config)

			var urlBuilder = URLComponents()
			urlBuilder.scheme = Mastodon.scheme
			urlBuilder.host = params.host
			urlBuilder.path = "/api/v1/timelines/home"
//			urlBuilder.queryItems = [URLQueryItem(name: "acct", value: "mattiem")]

			guard let url = urlBuilder.url else {
				throw AuthenticatorError.missingScheme
			}

			let request = URLRequest(url: url)

			let (data, response) = try await authenticator.response(for: request)
			
			let string = String(decoding: data, as: UTF8.self)
			
			print(response, string)
		} catch {
			print("hmmm", error)
		}
	}
}

#Preview {
	ContentView()
}
