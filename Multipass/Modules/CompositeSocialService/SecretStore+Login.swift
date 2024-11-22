import Foundation

import OAuthenticator

extension SecretStore {
	func loginStore(for key: String) -> LoginStorage {
		LoginStorage {
			guard let data = try await read(key) else {
				return nil
			}
			
			return try JSONDecoder().decode(Login.self, from: data)
		} storeLogin: { login in
			let data = try JSONEncoder().encode(login)
			
			try await write(data, key)
		}
	}
}
