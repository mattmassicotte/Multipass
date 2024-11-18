import SwiftSoup

public enum Token: Hashable, Sendable {
	case mention(String)
}

public struct PostDetails: Hashable, Sendable {
	public let content: String
	
	public init(content: String) {
		self.content = content
	}
}

public struct PostExtractor {
	public init() {
	}
	
	public func process(_ content: String) throws -> PostDetails {
		let doc = try SwiftSoup.parse(content)
		
		let text = try doc.select("p").first()?.text() ?? ""
		
		return PostDetails(content: text)
	}
}
