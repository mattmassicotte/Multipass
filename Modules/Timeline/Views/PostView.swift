import SwiftUI

import SocialModels

struct PostView: View {
	let post: CompositePost
	let action: (Post.Action) -> Void
	
	let formatter: RelativeDateTimeFormatter = {
		let formatter = RelativeDateTimeFormatter()
		
		formatter.dateTimeStyle = .named
		formatter.unitsStyle = .abbreviated
		formatter.formattingContext = .listItem

		return formatter
	}()

	init(post: CompositePost, action: @escaping (Post.Action) -> Void) {
		self.post = post
		self.action = action
	}

#if DEBUG
	init(post: Post) {
		self.post = CompositePost(post: post)
		self.action = { _ in }
	}
#endif

	private var rootPost: Post {
		post.posts.first!
	}

	var originalAuthor: Author {
		rootPost.repostingAuthor ?? rootPost.author
	}
	
	var repostAuthor: Author? {
		if rootPost.repostingAuthor == nil { return nil }
		return rootPost.author
	}

	var services: [SocialService] {
		post.posts.map { $0.source }
	}

	var emptyGridCell: some View {
		Color.clear
			.frame(maxWidth: 0, maxHeight: 0)
			.gridCellUnsizedAxes([.horizontal, .vertical])
	}
	
	var body: some View {
		Grid(horizontalSpacing: 12, verticalSpacing: 8) {
			if let repostAuthor {
				GridRow {
					emptyGridCell
					
					Label {
						HStack(spacing: 4) {
							Text("Reposted by:")
							
							AvatarView(url: repostAuthor.avatarURL)
								.frame(maxWidth: 12)
								.clipShape(Circle())
								.clipped()
							
							Text(repostAuthor.name)
						}
					} icon: {
						Image(systemName: "arrow.uturn.right")
					}
					.font(.caption2)
				}
			}
			
			GridRow(alignment: .top) {
				VStack(alignment: .trailing) {
					AvatarView(url: originalAuthor.avatarURL)
						.frame(maxWidth: 40)
						.cornerRadius(5)
					
					HStack {
						ForEach(services, id: \.self) { service in
							Image(service.imageName)
								.resizable()
								.scaledToFit()
								.frame(maxWidth: 12)
						}
					}
				}
				
				VStack(alignment: .leading, spacing: 8) {
					HStack(alignment: .top) {
						VStack(alignment: .leading) {
							Text(originalAuthor.name)
								.font(.subheadline)
							Text(originalAuthor.handle.displayString)
								.font(.caption2)
						}
						
						Spacer()
						
						Text(post.date, formatter: formatter)
							.font(.caption)
					}
					
					if let content = rootPost.content {
						PostContentView(content: content)
					}
					
					if !rootPost.attachments.isEmpty {
						PostAttachmentView(attachments: rootPost.attachments)
					}
				}
				.gridColumnAlignment(.leading)
			}
			
			GridRow {
				PostStatusView(
					postID: rootPost.id,
					source: rootPost.source,
					status: rootPost.status,
					action: action
				)
				#if os(macOS)
				.frame(maxWidth: 300)
				#endif
				.frame(maxWidth: .infinity, alignment: .trailing)
				.gridCellColumns(2)
			}
		}
		.padding(.horizontal, 12)
		.padding(.top, repostAuthor == nil ? 4 : 0)
		.padding(.vertical, 8)
	}
}

#Preview {
	VStack(spacing: 0) {
		Divider()
		
		PostView(post: Post(
			content: "hello",
			source: .mastodon,
			date: .now,
			author: Author.placeholder,
			repostingAuthor: nil,
			identifier: "abc123",
			url: URL(string: "https://example.com")!,
			attachments: [],
			status: .placeholder
		))
		
		Divider()
		
		PostView(post: Post(
			content: "hello",
			source: .mastodon,
			date: .now.addingTimeInterval(-3600),
			author: Author.placeholder,
			repostingAuthor: Author.placeholder,
			identifier: "abc123",
			url: URL(string: "https://example.com")!,
			attachments: [],
			status: .init(likeCount: 0, liked: false, repostCount: 0, reposted: false)
		))
		
		Divider()
		
		PostView(post: Post(
			content: "hello",
			source: .mastodon,
			date: .now,
			author: Author.placeholder,
			repostingAuthor: Author.placeholder,
			identifier: "abc123",
			url: URL(string: "https://example.com")!,
			attachments: [],
			status: .init(likeCount: 3, liked: true, repostCount: 999, reposted: false)
		))
		
		Divider()
	}
}
