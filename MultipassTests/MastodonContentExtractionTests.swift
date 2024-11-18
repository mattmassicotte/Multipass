import Testing
import Foundation

import MastodonContentExtraction

struct MastodonContentExtractionTests {
	@Test func processPlainParagraphPost() throws {
		let content = """
<p>hello</p>
"""
		
		let details = try PostExtractor().process(content)
		let expected = PostDetails(content: "hello")
		
		#expect(details == expected)
	}
	
	@Test func processReply() throws {
		let content = """
<p><span class="h-card" translate="no"><a href="https://mastodon.social/@person" class="u-url mention">@<span>person</span></a></span> hello</p>
"""
		let details = try PostExtractor().process(content)
		let expected = PostDetails(content: "@person hello")
		
		#expect(details == expected)
	}
}

