import SwiftUI

import CompositeSocialService

public struct PostStatusView: View {
	public let status: PostStatus
	
	var likeImageName: String {
		status.liked ? "heart.fill" : "heart"
	}
	
	var repostImageName: String {
		"arrow.2.squarepath"
	}
	
    public var body: some View {
		HStack {
			Image(systemName: likeImageName)
			Text("\(status.likeCount)")
			Image(systemName: repostImageName)
			Text("\(status.repostCount)")
		}
    }
}

#Preview {
	PostStatusView(status: PostStatus(likeCount: 0, liked: false, repostCount: 0, reposted: false))
}
