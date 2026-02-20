import Algorithms
import Foundation

import OAuthenticator
import Reblog

public struct MastodonClient: Sendable {
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
	
	private func load<Success: Decodable>(
		apiPath: String,
		queryItems: [URLQueryItem] = [],
		block: (inout URLRequest) -> Void = { _ in }
	) async throws -> Success {
		var components = baseComponents
		
		components.path = "/api/v1/\(apiPath)"
		
		components.queryItems = queryItems

		guard let url = components.url else {
			throw ClientError.malformedURL(components)
		}

		var request = URLRequest(url: url)
		
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		
		block(&request)

		let (data, response) = try await provider(request)
		
		guard
			let httpResponse = response as? HTTPURLResponse,
			httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
		else {
			print("unexpected data:", String(decoding: data, as: UTF8.self))
			print("response:", response)
			
			throw ClientError.unexpectedResponse(response)
		}

		
		return try decoder.decode(Success.self, from: data)
	}
}

extension MastodonClient {
	public func markers(timelines: Set<Marker.Timeline> = [.home, .notifications]) async throws -> MarkerResponse {
		var urlBuilder = baseComponents
		urlBuilder.path = "/api/v1/markers"
		urlBuilder.queryItems = [
			URLQueryItem(name: "timeline[]", value: "home"),
			URLQueryItem(name: "timeline[]", value: "notifications"),
		]

		guard let url = urlBuilder.url else {
			throw ClientError.malformedURL(urlBuilder)
		}

		let request = URLRequest(url: url)
		
		let (data, _) = try await provider(request)
		
		return try decoder.decode(MarkerResponse.self, from: data)
	}
	
	public func timeline(minimumId: String? = nil, maximumId: String? = nil, limit: Int = 20) async throws -> [Status] {
		try await load(
			apiPath: "timelines/home",
			queryItems: [
				URLQueryItem(name: "min_id", value: minimumId),
				URLQueryItem(name: "max_id", value: maximumId),
				URLQueryItem(name: "limit", value: String(limit)),
			]
		)
	}
	
	public func likePost(_ id: String) async throws -> Status {
		var components = baseComponents
		
		components.path = "/api/v1/statuses/\(id)/favourite"
		
		guard let url = components.url else {
			throw ClientError.malformedURL(components)
		}

		var request = URLRequest(url: url)
		
		request.httpMethod = "POST"
		
		let (data, _) = try await provider(request)
		
		return try decoder.decode(Status.self, from: data)
	}

	public func profiles(for ids: [String]) async throws -> [Account] {
		var total: [Account] = []

		for chunk in ids.chunks(ofCount: 20) {
			let partial: [Account] = try await load(
				apiPath: "accounts",
				queryItems: chunk.map { URLQueryItem(name: "id[]", value: $0) }
			)

			total.append(contentsOf: partial)
		}

		return total
	}
}
