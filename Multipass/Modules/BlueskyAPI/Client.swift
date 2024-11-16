import Foundation

enum ClientError: Error {
	case malformedURL(URLComponents)
}


public struct Client: Sendable {
	public typealias ResponseProvider = @Sendable (URLRequest) async throws -> (Data, URLResponse)
	
	private let provider: ResponseProvider
	public let host: String
	public let handle: String
	private let decoder = JSONDecoder()
	
	public init(host: String, handle: String, appPassword: String, provider: @escaping ResponseProvider) {
		self.provider = provider
		self.host = host
		self.handle = handle
		
		let formatter = DateFormatter()
		
		// 2024-11-15T18:16:35.907Z
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		
		decoder.dateDecodingStrategy = .formatted(formatter)
	}
	
	private var baseComponents: URLComponents {
		var components = URLComponents()
		components.scheme = "https"
		components.host = host
		
		return components
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

public typealias ATProtoDID = String
public typealias ATProtoURI = String
public typealias ATProtoCID = String

public enum AccountStatus: String, Decodable, Hashable, Sendable {
	case takenDown = "takendown"
	case suspended
	case deactivated
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

public struct Record: Decodable, Hashable, Sendable {
	public let createdAt: Date
	public let langs: [String]?
	public let text: String
}

public struct Post: Decodable, Hashable, Sendable {
	public let uri: ATProtoURI
	public let cid: ATProtoCID
	public let record: Record
	public let replyCount: Int
	public let repostCount: Int
	public let likeCount: Int
	public let quoteCount: Int
	public let indexedAt: Date
}

public struct Reply: Decodable, Hashable, Sendable {
}

public struct FeedEntry: Decodable, Hashable, Sendable {
	public let post: Post
	public let reply: Reply?
//	public let feedContext: String
}

public struct TimelineResponse: Decodable, Hashable, Sendable {
	public let cursor: String
	public let feed: [FeedEntry]
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
	
	public func timeline(token: String) async throws -> TimelineResponse {
		var components = baseComponents
		
		components.path = "/xrpc/app.bsky.feed.getTimeline"
		
		guard let url = components.url else {
			throw ClientError.malformedURL(components)
		}

		var request = URLRequest(url: url)
		
		request.httpMethod = "GET"
		request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		
		let (data, _) = try await provider(request)
		
		return try decoder.decode(TimelineResponse.self, from: data)
	}
}
