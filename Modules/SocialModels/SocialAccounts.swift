public struct SocialAccounts {
	let services: [SocialService: any SocialAccount]

	public init(services: [any SocialAccount]) {
		var serviceDict: [SocialService: any SocialAccount] = [:]

		for service in services {
			if serviceDict[service.platform] != nil { continue }

			serviceDict[service.platform] = service
		}

		self.services = serviceDict
	}

	public func service(for platform: SocialService) -> (any SocialAccount)? {
		services[platform]
	}
}
