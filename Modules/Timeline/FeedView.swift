import CompositeSocialService
import StableView
import Storage
import SwiftUI
import UIUtility

public struct FeedView: View {
	@State private var model: FeedViewModel
	@Environment(UserAccountStore.self) private var accountStore
	@Environment(\.openURL) private var openURL
	@State private var newPosition: ScrollPosition = .init(idType: Post.ID.self)

	public init(secretStore: SecretStore, timelineStore: TimelineStore) {
		self._model = State(
			wrappedValue: FeedViewModel(
				secretStore: secretStore,
				timelineStore: timelineStore
			)
		)
	}

	public var body: some View {
		Text("Items Above: \(model.aboveCount)")
		AnchoredList(items: model.posts, position: $model.positionAnchor) { post, row in
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
