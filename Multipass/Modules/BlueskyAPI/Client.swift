import Foundation

enum ClientError: Error {
	case malformedURL(URLComponents)
	case requestFailed
}

public struct BlueskyJSONDecoder: Sendable {
	public let decoder = JSONDecoder()
	private let iso8061DecimalDecoder: DateFormatter
	private let iso8061OffsetFormatter: DateFormatter

	public init() {
		self.iso8061DecimalDecoder = DateFormatter()
		
		// 2024-11-15T18:16:35.907Z
		iso8061DecimalDecoder.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		
		self.iso8061OffsetFormatter = DateFormatter()
		
		// 2024-11-17T12:23:53+00:00
		iso8061OffsetFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
		
		decoder.dateDecodingStrategy = .custom(decodeDate)
	}
	
	private func decodeDate(_ decoder: any Decoder) throws -> Date {
		let container = try decoder.singleValueContainer()
		let string = try container.decode(String.self)
		
		if let date = iso8061DecimalDecoder.date(from: string) {
			return date
		}
		
		if let date = iso8061OffsetFormatter.date(from: string) {
			return date
		}
		
		throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Undecodable date \(string)"))
	}
}

public actor Client: Sendable {
	public typealias ResponseProvider = @Sendable (URLRequest) async throws -> (Data, URLResponse)
	
	private let provider: ResponseProvider
	public let host: String
	private let decoder = JSONDecoder()
	private let iso8061DecimalDecoder: DateFormatter
	private let iso8061OffsetFormatter: DateFormatter
	
	public init(host: String, provider: @escaping ResponseProvider) {
		self.provider = provider
		self.host = host
		
		self.iso8061DecimalDecoder = DateFormatter()
		
		// 2024-11-15T18:16:35.907Z
		iso8061DecimalDecoder.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		
		self.iso8061OffsetFormatter = DateFormatter()
		
		// 2024-11-17T12:23:53+00:00
		iso8061OffsetFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
		
		decoder.dateDecodingStrategy = .custom(decodeDate)
	}
	
	private var baseComponents: URLComponents {
		var components = URLComponents()
		components.scheme = "https"
		components.host = host
		
		return components
	}
	
	private nonisolated func decodeDate(_ decoder: any Decoder) throws -> Date {
		let container = try decoder.singleValueContainer()
		let string = try container.decode(String.self)
		
		if let date = iso8061DecimalDecoder.date(from: string) {
			return date
		}
		
		if let date = iso8061OffsetFormatter.date(from: string) {
			return date
		}
		
		throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Undecodable date \(string)"))
	}
}

public struct Credentials: Hashable, Codable, Sendable {
	public let identifier: String
	public let password: String
	
	public init(identifier: String, password: String) {
		self.identifier = identifier
		self.password = password
	}
}


public struct CreateSessionResponse: Decodable, Hashable, Sendable {
	public let accessJwt: String
	public let refreshJwt: String
	public let handle: String
	public let did: ATProtoDID
//	public let didDoc: ATProtoDIDDoc
	public let email: String
	public let emailConfirmed: Bool
	public let emailAuthFactor: Bool
	public let active: Bool
	public let status: AccountStatus?
}

extension Client {
	public func createSession(with login: Credentials) async throws -> CreateSessionResponse {
		var components = baseComponents
		
		components.path = "/xrpc/com.atproto.server.createSession"
		
		guard let url = components.url else {
			throw ClientError.malformedURL(components)
		}

		var request = URLRequest(url: url)
		
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = try JSONEncoder().encode(login)
		
		let (data, _) = try await provider(request)
		
		return try decoder.decode(CreateSessionResponse.self, from: data)
	}
	
	public func timeline() async throws -> TimelineResponse {
		var components = baseComponents
		
		components.path = "/xrpc/app.bsky.feed.getTimeline"
		
		guard let url = components.url else {
			throw ClientError.malformedURL(components)
		}

		var request = URLRequest(url: url)
		
		request.httpMethod = "GET"
		
		let (data, response) = try await provider(request)
		
		guard
			let httpResponse = response as? HTTPURLResponse,
			httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
		else {
			print("response:", response)
			print(String(decoding: data, as: UTF8.self))
			throw ClientError.requestFailed
		}
		
		print(String(decoding: data, as: UTF8.self))
		
		return try decoder.decode(TimelineResponse.self, from: data)
	}
}
