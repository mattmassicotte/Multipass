import Testing
import BlueskyAPI
import Foundation

struct BlueskyAPITests {
    @Test
	func imageEmbedDecode() throws {
		let json = """
{"$type":"app.bsky.embed.images","images":[{"alt":"This is alt text","aspectRatio":{"height":2000,"width":1500},"image":{"$type":"blob","ref":{"$link":"bafkreih6jynjnlbr5euod3iwnv6d76jyae7vvrzjfwxl2zt5szdkouivre"},"mimeType":"image/jpeg","size":692914}}]}
"""
		
		let embed = try JSONDecoder().decode(Embed.self, from: Data(json.utf8))
		
		guard case let .images(images) = embed else {
			fatalError()
		}
		
		#expect(images.images.count == 1)
		#expect(images.images[0].aspectRatio == Embed.AspectRatio(height: 2000, width: 1500))
		#expect(images.images[0].image.mimeType == "image/jpeg")
		#expect(images.images[0].image.size == 692914)
    }

	@Test
	func imagesViewEmbedDecode() throws {
		let json = """
{"$type":"app.bsky.embed.images#view","images":[{"thumb":"https://cdn.bsky.app/img/feed_thumbnail/plain/did:plc:alxua43vihfglhauab7jwezt/bafkreih6jynjnlbr5euod3iwnv6d76jyae7vvrzjfwxl2zt5szdkouivre@jpeg","fullsize":"https://cdn.bsky.app/img/feed_fullsize/plain/did:plc:alxua43vihfglhauab7jwezt/bafkreih6jynjnlbr5euod3iwnv6d76jyae7vvrzjfwxl2zt5szdkouivre@jpeg","alt":"This is alt text","aspectRatio":{"height":2000,"width":1500}}]}
"""
		
		let embed = try JSONDecoder().decode(Embed.self, from: Data(json.utf8))
		
		guard case let .imagesView(imagesView) = embed else {
			fatalError()
		}
		
		#expect(imagesView.images.count == 1)
		
		let image = try #require(imagesView.images.first)
		
		#expect(image.thumb == "https://cdn.bsky.app/img/feed_thumbnail/plain/did:plc:alxua43vihfglhauab7jwezt/bafkreih6jynjnlbr5euod3iwnv6d76jyae7vvrzjfwxl2zt5szdkouivre@jpeg")
		#expect(image.fullsize == "https://cdn.bsky.app/img/feed_fullsize/plain/did:plc:alxua43vihfglhauab7jwezt/bafkreih6jynjnlbr5euod3iwnv6d76jyae7vvrzjfwxl2zt5szdkouivre@jpeg")

	}
	
	@Test
	func repostDecode() throws {
		let json = """
{"post":{"uri":"at://did:plc:niay7ajcptgklwrhknvnhk44/app.bsky.feed.post/3lhjnkjle5s2o","cid":"bafyreiaicb72bvulmvdafwzock4lsvarcx4bp54u4dri4jcrkjly5o5dla","author":{"did":"did:plc:niay7ajcptgklwrhknvnhk44","handle":"theferrarilab.bsky.social","displayName":"The Ferrari Lab","avatar":"https://cdn.bsky.app/img/avatar/plain/did:plc:niay7ajcptgklwrhknvnhk44/bafkreigtm5lw5smbvpisds2ozcrk7vovmp47jxkp5yi5en7ftdzxl5aqpy@jpeg","viewer":{"muted":false,"blockedBy":false},"labels":[],"createdAt":"2023-07-29T01:17:56.883Z"},"record":{"$type":"app.bsky.feed.post","createdAt":"2025-02-06T17:50:33.851Z","embed":{"$type":"app.bsky.embed.record","record":{"cid":"bafyreibox6hwfri43nvhrpmi4sznpzhpy3rvxr4pgkf6z6rtttjyiq27ua","uri":"at://did:plc:k5nskatzhyxersjilvtnz4lh/app.bsky.feed.post/3lhjg47rc6c2o"}},"langs":["en"],"text":"Rule 2. If you ever find yourself in a bar fight and someone wants to join in on your side, don't bring up old s**t until the fight is over. \\n\\nRule 1. Know when you are in a bar fight.\\n\\nWelcome to the fight, farmers."},"embed":{"$type":"app.bsky.embed.record#view","record":{"$type":"app.bsky.embed.record#viewRecord","uri":"at://did:plc:k5nskatzhyxersjilvtnz4lh/app.bsky.feed.post/3lhjg47rc6c2o","cid":"bafyreibox6hwfri43nvhrpmi4sznpzhpy3rvxr4pgkf6z6rtttjyiq27ua","author":{"did":"did:plc:k5nskatzhyxersjilvtnz4lh","handle":"washingtonpost.com","displayName":"The Washington Post","avatar":"https://cdn.bsky.app/img/avatar/plain/did:plc:k5nskatzhyxersjilvtnz4lh/bafkreicx5ybi5wukvetsv3m74z3nmvbvrdhgms6sr4nlilrktv5u2lmsay@jpeg","associated":{"chat":{"allowIncoming":"following"}},"viewer":{"muted":false,"blockedBy":false},"labels":[],"createdAt":"2023-05-01T18:57:05.658Z"},"value":{"$type":"app.bsky.feed.post","createdAt":"2025-02-06T15:37:17.606Z","embed":{"$type":"app.bsky.embed.external","external":{"description":"U.S. businesses that sold goods and services to USAID are in limbo, including American farms dealing in rice, wheat and soybeans.","thumb":{"$type":"blob","ref":{"$link":"bafkreidkonskmf77ctno6ilvuxdkzeffichjfk65ycwawtm2qeecyz3hxe"},"mimeType":"image/jpeg","size":313186},"title":"Gutting USAID threatens billions of dollars for U.S. farms, businesses","uri":"https://www.washingtonpost.com/politics/2025/02/06/trump-usaid-money-american-farms/?utm_campaign=wp_main&utm_medium=social&utm_source=bluesky"}},"langs":["en"],"text":"U.S. businesses that sold goods and services to USAID are in limbo, including American farms dealing in rice, wheat and soybeans purchased as food aid."},"labels":[],"likeCount":1700,"replyCount":193,"repostCount":722,"quoteCount":217,"indexedAt":"2025-02-06T15:37:19.452Z","embeds":[{"$type":"app.bsky.embed.external#view","external":{"uri":"https://www.washingtonpost.com/politics/2025/02/06/trump-usaid-money-american-farms/?utm_campaign=wp_main&utm_medium=social&utm_source=bluesky","title":"Gutting USAID threatens billions of dollars for U.S. farms, businesses","description":"U.S. businesses that sold goods and services to USAID are in limbo, including American farms dealing in rice, wheat and soybeans.","thumb":"https://cdn.bsky.app/img/feed_thumbnail/plain/did:plc:k5nskatzhyxersjilvtnz4lh/bafkreidkonskmf77ctno6ilvuxdkzeffichjfk65ycwawtm2qeecyz3hxe@jpeg"}}]}},"replyCount":1,"repostCount":7,"likeCount":9,"quoteCount":0,"indexedAt":"2025-02-06T17:50:34.148Z","viewer":{"threadMuted":false,"embeddingDisabled":false},"labels":[]},"reason":{"$type":"app.bsky.feed.defs#reasonRepost","by":{"did":"did:plc:lw5dadzkguntwgkj2jxmulxk","handle":"daniloc.xyz","displayName":"Danilo 🇵🇷","avatar":"https://cdn.bsky.app/img/avatar/plain/did:plc:lw5dadzkguntwgkj2jxmulxk/bafkreibfpv3q3s3b5xmooejbb4aidx4litq4lzfueztlmfxku4minr7hu4@jpeg","viewer":{"muted":false,"blockedBy":false,"following":"at://did:plc:klsh7edzj3jmxucibyjqstb3/app.bsky.graph.follow/3lapa4bowrn2l","followedBy":"at://did:plc:lw5dadzkguntwgkj2jxmulxk/app.bsky.graph.follow/3lapa7cn4kw2a"},"labels":[],"createdAt":"2023-04-30T17:08:16.864Z"},"indexedAt":"2025-02-06T17:58:31.348Z"}}
"""
		
		let decoder = BlueskyJSONDecoder()
		let entry = try decoder.decoder.decode(TimelineResponse.FeedEntry.self, from: Data(json.utf8))
		
		guard case let .feedReasonRepost(value) = entry.reason else {
			fatalError()
		}
		
		#expect(value.by.did == "did:plc:lw5dadzkguntwgkj2jxmulxk")
	}
}
