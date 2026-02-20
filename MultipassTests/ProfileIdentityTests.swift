import Testing

import SocialModels
import Storage

struct ProfileIdentityTests {
	@Test
	func dissimilar() async throws {
		let identity = CompositeProfile(
			name: "Korben",
			handles: [
				Handle(host: "dallas.net", name: "korben", service: .mastodon)
			]
		)

		let author = Author(
			name: "Leeloo",
			platformId: "2",
			handle: Handle(host: "elements.com", name: "leeloo", service: .mastodon)
		)
		#expect(identity.compare(to: author, on: .mastodon) == .dissimilar)
	}

	@Test
	func similarNames() async throws {
		let identity = CompositeProfile(
			name: "Korben",
			handles: [
				Handle(host: "dallas.net", name: "korben", service: .bluesky)
			]
		)

		let author = Author(
			name: "Korben",
			platformId: "1",
			handle: Handle(host: "thingy.social", name: "korben", service: .mastodon)
		)
		#expect(identity.compare(to: author, on: .mastodon) == .similar)
	}

	@Test
	func similarNameToDomain() async throws {
		let identity = CompositeProfile(
			name: "Korben",
			handles: [
				Handle(host: "korben.dallas", name: "", service: .bluesky)
			]
		)

		let author = Author(
			name: "k-man",
			platformId: "1",
			handle: Handle(host: "thingy.social", name: "korbendallas", service: .mastodon)
		)
		#expect(identity.compare(to: author, on: .mastodon) == .similar)
	}

	@Test
	func similarIdentityBeforeSame() throws {
		let authorA = Author(name: "Korben", platformId: "1", handle: "korbendallas", host: "zorg.social", platform: .mastodon)
		let authorB = Author(name: "Korben", platformId: "a", handle: "", host: "korben.dallas", platform: .bluesky)

		// b is similar to the first entry, but identical to the second
		let identity = CompositeProfile(
			name: "Korben Dallas",
			handles: [
				authorA.handle,
				authorB.handle,
			]
		)

		#expect(identity.compare(to: authorA, on: .mastodon) == .same)
		#expect(identity.compare(to: authorB, on: .bluesky) == .same)
	}
}
