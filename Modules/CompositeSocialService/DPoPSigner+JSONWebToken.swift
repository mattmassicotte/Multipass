import CryptoKit
import Foundation

import JSONWebToken
import JSONWebKey
import JSONWebSignature
import OAuthenticator

struct DPoPKey: Codable {
	let data: Data
	let id: UUID

	init() {
		self.id = UUID()
		self.data = P256.Signing.PrivateKey().rawRepresentation
	}
}

struct DPoPTokenClaims: JWTRegisteredFieldsClaims, Codable {
	let iss: String?
	let sub: String?
	let aud: [String]?
	let exp: Date?
	let nbf: Date?
	let iat: Date?
	let jti: String?

	let htm: String?
	let htu: String?
	let nonce: String?
	let ath: String?

	func validateExtraClaims() throws {
	}

	/// for token endpoint requests
	///
	/// nonce could potentially be known at this point
	init(httpMethod: String, requestEndpoint: String, nonce: String? = nil) {
		let now = Date.now

		self.iss = nil
		self.jti = UUID().uuidString
		self.sub = nil
		self.aud = nil
		self.exp = now.addingTimeInterval(60.0)
		self.nbf = nil
		self.iat = now
		self.htm = httpMethod
		self.htu = requestEndpoint
		self.nonce = nonce
		self.ath = nil
	}

	init(authorizationServerIssuer: String?, accessTokenHash: String?, httpMethod: String, requestEndpoint: String, nonce: String?) {
		let now = Date.now

		self.iss = authorizationServerIssuer
		self.jti = UUID().uuidString
		self.sub = nil
		self.aud = nil
		self.exp = now.addingTimeInterval(60.0)
		self.nbf = nil
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
			let key = try P256.Signing.PrivateKey(rawRepresentation: dpopKey.data)
			let header = DefaultJWSHeaderImpl(algorithm: .ES256, keyID: id, jwk: key.publicKey.jwk, type: params.keyType)
			let claims = DPoPTokenClaims(
				authorizationServerIssuer: params.issuingServer,
				accessTokenHash: params.tokenHash,
				httpMethod: params.httpMethod,
				requestEndpoint: params.requestEndpoint,
				nonce: params.nonce
			)

			let jwt = try JWT.signed(
				payload: claims,
				protectedHeader: header,
				key: key
			)

			return jwt.jwtString
		}
	}
}
