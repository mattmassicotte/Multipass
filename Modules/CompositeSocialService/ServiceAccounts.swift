public struct ServiceAccounts {
	let services: [SocialPlatform: any SocialAccount]

	public init(services: [any SocialAccount]) {
		var serviceDict: [SocialPlatform: any SocialAccount] = [:]

		for service in services {
			if serviceDict[service.platform] != nil { continue }

			serviceDict[service.platform] = service
		}

		self.services = serviceDict
	}

	public func service(for platform: SocialPlatform) -> (any SocialAccount)? {
		services[platform]
	}
}
