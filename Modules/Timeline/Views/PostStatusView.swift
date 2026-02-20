import SwiftUI

import SocialModels
import Storage

public struct PostStatusView: View {
	public let postID: Post.ID
	public let source: SocialService
	public let status: PostStatus
	public let action: (Post.Action) -> Void
	
    public var body: some View {
		HStack {
			Button {
				/// Reply
			} label: {
				Label {
					Text("Reply")
				} icon: {
					Image(systemName: "bubble")
				}
			}
			.labelStyle(.iconOnly)
			.disabled(true)
			.frame(maxWidth: .infinity)
			
			Button {
				action(.repost(postID))
			} label: {
				Label {
					Text("\(status.repostCount)")
						.font(.subheadline)
				} icon: {
					Image(systemName: "arrow.2.squarepath")
						.bold(status.reposted)
				}
				.accessibilityLabel(status.reposted ? "Reposted" : "Repost")
			}
			.accentColor(status.reposted ? .accentColor : .primary)
			.frame(maxWidth: .infinity)
			
			Button {
				if status.liked {
					action(.unlike(postID))
				} else {
					action(.like(postID))
				}
			} label: {
				Label {
					Text("\(status.likeCount)")
						.font(.subheadline)
				} icon: {
					if status.liked {
						Image(systemName: "heart.fill")
					} else {
						Image(systemName: "heart")
					}
				}
				.accessibilityLabel(status.liked ? "Unlike" : "Like")
			}
			.accentColor(status.liked ? .accentColor : .primary)
			.frame(maxWidth: .infinity)
			
			Button {
				/// Share
				action(.repost(postID))
			} label: {
				Label {
					Text("Share")
				} icon: {
					Image(systemName: "square.and.arrow.up")
				}
			}
			.labelStyle(.iconOnly)
			.disabled(true)
			.frame(maxWidth: .infinity)
		}
		.accentColor(.primary)
		.labelIconToTitleSpacing(2)
    }
}

#Preview {
	VStack {
		PostStatusView(
			postID: "1",
			source: .mastodon,
			status: PostStatus(
				likeCount: 0,
				liked: false,
				repostCount: 0,
				reposted: false
			)
		) { _ in }
		
		PostStatusView(
			postID: "2",
			source: .mastodon,
			status: PostStatus(
				likeCount: 3,
				liked: true,
				repostCount: 4,
				reposted: true
			)
		) { _ in }
	}
}
