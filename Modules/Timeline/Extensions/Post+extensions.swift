//
//  Post+extensions.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-02-18.
//

import Foundation

import SocialModels

extension Post {
	public enum Action {
		case like(Post.ID)
		case unlike(Post.ID)
		case repost(Post.ID)
		case group(Post.ID, toDate: Date)
		
		var postID: Post.ID {
			switch self {
			case let .like(id): id
			case let .unlike(id): id
			case let .repost(id): id
			case let .group(id, _): id
			}
		}
		
		public enum Error: LocalizedError, Hashable, Sendable {
			case unableToLikePost(id: Post.ID)
			case unableToUnlikePost(id: Post.ID)
			case unableToRepostPost(id: Post.ID)
			case unableToGroupPost(id: Post.ID)
			
			public var errorDescription: String? {
				switch self {
				case let .unableToLikePost(id):
					"Unable to like post id: \(id)"
				case let .unableToUnlikePost(id):
					"Unable to unlike post id: \(id)"
				case let .unableToRepostPost(id):
					"Unable to repost post id: \(id)"
				case let .unableToGroupPost(id):
					"Unable to group post id: \(id)"
				}
			}
		}
	}
}
