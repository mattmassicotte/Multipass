import SwiftUI

import CompositeSocialService
import StableView
import Storage
import UIUtility

public struct FeedView: View {
	@State private var model: FeedViewModel
	@State private var scrollState: AnchoredListPosition<Post> = .absolute(0.0)
	@Environment(UserAccountStore.self) private var accountStore
	@Environment(\.openURL) private var openURL
	
	public init(secretStore: SecretStore) {
		self._model = State(wrappedValue: FeedViewModel(secretStore: secretStore))
	}
	
	public var body: some View {
		AnchoredList(items: model.posts, scrollState: $scrollState) { post, row in
//		List(model.posts, id: \.self) { post in
			PostView(
				post: post,
				actionHandler: { action in
					model.handlePostAction(action: action, post: post)	
				}
			)
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.vertical, 6.0)
			.contextMenu {
				if let url = post.url {
					Button("Open Link") {
						openURL(url)
					}
				}
			}
		}
		.listStyle(PlainListStyle())
		.onChange(of: accountStore.accounts, initial: true, { _, newValue in
			model.updateAccounts(newValue)
		})
#if os(macOS)
		.focusedSceneValue(\.refreshAction) {
			Task {
				await model.refresh()
			}
		}
#else
		.refreshable {
			await model.refresh()
		}
#endif
		.task(id: model.accountsIdentifier) {
			await model.refresh()
		}
	}
}
