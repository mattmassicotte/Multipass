import SwiftUI

import CompositeSocialService

@MainActor
struct LikeAction {
	public func callAsFunction() {
		
	}
}

public enum PostStatusAction {
	case like
	case repost
}

public struct PostStatusView: View {
	public typealias ActionHandler = (PostStatusAction) -> Void
	
	public let source: DataSource
	public let status: PostStatus
	public let actionHandler: ActionHandler
	
	var likeImageName: String {
		status.liked ? "heart.fill" : "heart"
	}
	
	var repostImageName: String {
		"arrow.2.squarepath"
	}
	
    public var body: some View {
		HStack {
			Image(source.imageName)
			Image(systemName: likeImageName)
				.onTapGesture {
					actionHandler(.like)
				}
			Text("\(status.likeCount)")
			Image(systemName: repostImageName)
				.onTapGesture {
					actionHandler(.repost)
				}
			Text("\(status.repostCount)")
		}
    }
}

#Preview {
	PostStatusView(
		source: .mastodon,
		status: PostStatus(likeCount: 0, liked: false, repostCount: 0, reposted: false),
		actionHandler: { _ in }
	)
}
