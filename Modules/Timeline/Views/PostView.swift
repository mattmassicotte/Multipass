import SwiftUI

import CompositeSocialService
import SocialModels

struct PostView: View {
	let post: Post
	let action: (Post.Action) -> Void
	
	let formatter: RelativeDateTimeFormatter = {
		let formatter = RelativeDateTimeFormatter()
		
		formatter.dateTimeStyle = .named
		formatter.unitsStyle = .abbreviated
		formatter.formattingContext = .listItem

		return formatter
	}()
	
	var originalAuthor: Author {
		post.repostingAuthor ?? post.author
	}
	
	var repostAuthor: Author? {
		if post.repostingAuthor == nil { return nil }
		return post.author
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
						/// Could put more sources here for merged posts
						Image(post.source.imageName)
							.resizable()
							.scaledToFit()
							.frame(maxWidth: 12)
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
					
					if let content = post.content {
						PostContentView(content: content)
					}
					
					if !post.attachments.isEmpty {
						PostAttachmentView(attachments: post.attachments)
					}
				}
				.gridColumnAlignment(.leading)
			}
			
			GridRow {
				PostStatusView(
					postID: post.id,
					source: post.source,
					status: post.status,
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
		), action: { _ in })
		
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
		), action: { _ in })
		
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
		), action: { _ in })
		
		Divider()
	}
}
