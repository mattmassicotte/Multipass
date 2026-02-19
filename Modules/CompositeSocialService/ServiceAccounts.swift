public struct ServiceAccounts {
	let services: [SocialPlatform: any SocialService]

	public init(services: [any SocialService]) {
		var serviceDict: [SocialPlatform: any SocialService] = [:]

		for service in services {
			if serviceDict[service.platform] != nil { continue }

			serviceDict[service.platform] = service
		}

		self.services = serviceDict
	}

	public func service(for platform: SocialPlatform) -> (any SocialService)? {
		services[platform]
	}
}
