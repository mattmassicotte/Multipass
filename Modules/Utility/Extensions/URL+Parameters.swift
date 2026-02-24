import Foundation

extension URL {
	public static let nonessentialParameters: Set<String> = [
		"fbclid",
		"gclid",
		"gclsrc",
		"gPromoCode",
		"gQT",
		"dclid",
		"gbraid",
		"wbraid",
		"gad_source",
		"gad_campaignid",
		"srsltid",
		"twclid",
		"yclid",
		"utm_brand",
		"utm_campaign",
		"utm_content",
		"utm_term",
		"utm_medium",
		"utm_social-type",
		"utm_source",
		"utm_id",
		"utm_source_platform",
		"utm_creative_format",
		"utm_marketing_tactic",
		"_ga",
		"_gl",
		"ef_id",
		"s_kwcid",
		"msclkid",
		"igshid",
		"si",
	]

	public func removingParameters(in set: Set<String>) -> URL {
		guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
			return self
		}

		components.queryItems?.removeAll { item in
			set.contains(item.name)
		}

		if components.queryItems?.isEmpty == true {
			components.queryItems = nil
		}

		return components.url ?? self
	}
}
