import Testing
import Foundation

import MastodonAPI

struct MastodonAPITests {
	@Test func markerDecode() async throws {
		let data = """
{"home":{"last_read_id":"112327167530043732","version":425,"updated_at":"2024-04-24T16:38:07.000Z"},"notifications":{"last_read_id":"339514663","version":12806,"updated_at":"2024-11-15T18:16:35.000Z"}}
"""
		
		let client = MastodonAPI.Client(host: "abc", provider: { _ in
			return (Data(data.utf8), URLResponse())
		})
		
		let markers = try await client.markers()
		
		let expected = MarkerResponse(
			home: Marker(lastReadId: "112327167530043732", version: 425, updatedAt: Date(timeIntervalSince1970: 1713976687)),
			notifications: Marker(lastReadId: "339514663", version: 12806, updatedAt: Date(timeIntervalSince1970: 1731694595))
		)
		#expect(markers == expected)
	}
}
