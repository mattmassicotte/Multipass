import CryptoKit
import Foundation

import Jot
import OAuthenticator

struct DPoPTokenClaims : JSONWebTokenPayload {
	// standard claims
	let iss: String?
	let jti: String?
	let iat: Date?
	let exp: Date?
	
	// custom claims
	let htm: String?
	let htu: String?
	let nonce: String?
	let ath: String?
	
	init(authorizationServerIssuer: String?, accessTokenHash: String?, httpMethod: String, requestEndpoint: String, nonce: String?) {
		let now = Date.now

		self.iss = authorizationServerIssuer
		self.jti = UUID().uuidString
		self.exp = now.addingTimeInterval(60.0)
		self.iat = now
		self.htm = httpMethod
		self.htu = requestEndpoint
		self.nonce = nonce
		self.ath = accessTokenHash
	}
}

extension DPoPSigner {
	static func JSONWebTokenGenerator(dpopKey: DPoPKey) -> DPoPSigner.JWTGenerator {
		let id = dpopKey.id.uuidString
		
		return { params in
			let key = try dpopKey.p256PrivateKey
			
			let jwk = JSONWebKey(p256Key: key.publicKey)
			
			let newToken = JSONWebToken<DPoPTokenClaims>(
				header: JSONWebTokenHeader(
					algorithm: .ES256,
					type: params.keyType,
					keyId: id,
					jwk: jwk
				),
				payload: DPoPTokenClaims(
					authorizationServerIssuer: params.issuingServer,
					accessTokenHash: params.tokenHash,
					httpMethod: params.httpMethod,
					requestEndpoint: params.requestEndpoint,
					nonce: params.nonce
				)
			)
			
			return try newToken.encode(with: key)
		}
	}
}
