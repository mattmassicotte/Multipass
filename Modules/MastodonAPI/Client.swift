import Foundation

import Reblog

public struct Client: Sendable {
	public typealias ResponseProvider = @Sendable (URLRequest) async throws -> (Data, URLResponse)
	
	private let provider: ResponseProvider
	private let decoder = JSONDecoder()
	public let host: String
	
	public init(host: String, provider: @escaping ResponseProvider) {
		self.provider = provider
		self.host = host
		
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

enum MastodonError: Error {
	case malformedURL(URLComponents)
}

extension Client {
	public func markers(timelines: Set<Marker.Timeline> = [.home, .notifications]) async throws -> MarkerResponse {
		var urlBuilder = baseComponents
		urlBuilder.path = "/api/v1/markers"
		urlBuilder.queryItems = [
			URLQueryItem(name: "timeline[]", value: "home"),
			URLQueryItem(name: "timeline[]", value: "notifications"),
		]

		guard let url = urlBuilder.url else {
			throw MastodonError.malformedURL(urlBuilder)
		}

		let request = URLRequest(url: url)
		
		let (data, _) = try await provider(request)
		
		return try decoder.decode(MarkerResponse.self, from: data)
	}
	
	public func timeline() async throws -> [Status] {
		var components = baseComponents
		
		components.path = "/api/v1/timelines/home"

		guard let url = components.url else {
			throw MastodonError.malformedURL(components)
		}

		let request = URLRequest(url: url)
		
		let (data, _) = try await provider(request)
		
		return try decoder.decode([Status].self, from: data)
	}
	
	public func likePost(_ id: String) async throws -> Status {
		var components = baseComponents
		
		components.path = "/api/v1/statuses/\(id)/favourite"
		
		guard let url = components.url else {
			throw MastodonError.malformedURL(components)
		}

		var request = URLRequest(url: url)
		
		request.httpMethod = "POST"
		
		let (data, _) = try await provider(request)
		
		return try decoder.decode(Status.self, from: data)
	}
}
