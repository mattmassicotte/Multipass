import Foundation

import Profiles
import SocialModels
import Utility

public final class FragmentProcessor {
	public typealias AuthorResolver = (_ author: Author) async throws -> CompositeProfile

	public let authorResolver: AuthorResolver

	public init(authorResolver: @escaping AuthorResolver = FragmentProcessor.identityResolver) {
		self.authorResolver = authorResolver
	}

	public func merge(fragment: TimelineFragment, with posts: [CompositePost]) async throws -> [CompositePost] {
		var mergedPosts: [CompositePost] = posts
		var remainingNewPosts = fragment.posts

		for i in 0..<mergedPosts.count {
			var current = mergedPosts[i]

			for j in 0..<remainingNewPosts.count {
				let newPost = remainingNewPosts[j]

				var merged = false

				for subPost in current.posts {
					if try await comparePosts(subPost, newPost) {
						current.merge(newPost)
						mergedPosts[i] = current
						remainingNewPosts.remove(at: j)
						merged = true
						print("merged!")
						print(subPost)
						print(newPost)
						break
					}
				}

				if merged {
					break
				}
			}
		}

		// now, we have to add in any new posts that were not duplicates
		mergedPosts.append(contentsOf: remainingNewPosts.map { CompositePost(post: $0)} )

		return mergedPosts.sorted(by: >)
	}

	func comparePosts(_ a: Post, _ b: Post) async throws -> Bool {
		if let authorA = a.repostingAuthor, let authorB = b.repostingAuthor {
			let identity = try await authorResolver(authorA)

			if identity.compare(to: authorB, on: b.source) == .dissimilar {
				return false
			}
		}

		let identity = try await authorResolver(a.author)
		let identitySimilarity = identity.compare(to: b.author, on: b.source)
		if identitySimilarity == .dissimilar {
			return false
		}

		let aLinks = a.links.map { $0.url.removingParameters(in: URL.nonessentialParameters) }
		let bLinks = b.links.map { $0.url.removingParameters(in: URL.nonessentialParameters) }
		let sameLinks = aLinks == bLinks

		if sameLinks && aLinks.isEmpty == false {
			return true
		}

		let contentSimilarity: Float

		// this is a weird thing to do need to do, but it is necessary at least for now
		// https://forums.swift.org/t/attributedstring-to-string/61667
		let contentA = a.content.map { String($0.characters[...]) }
		let contentB = b.content.map { String($0.characters[...]) }

		if let contentA, let contentB, contentA.isEmpty == false {
			contentSimilarity = contentA.similarity(to: contentB)
		} else {
			contentSimilarity = 0.0
		}

		return contentSimilarity > 0.9
	}
}

extension FragmentProcessor {
	public static func identityResolver(author: Author) async throws -> CompositeProfile {
		return CompositeProfile(
			name: author.name,
			handles: [author.handle],
			avatarURL: author.avatarURL
		)
	}
}
