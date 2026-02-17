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
		VStack {
			if model.timeline.elements.isEmpty {
				List {
					Text("Empty List")
				}
			} else {
				Text("Items Above: \(model.aboveCount)")
				List(model.timeline.elements) { entry in
					switch entry {
					case let .gap(gap):
						GapView(gap: gap) { loadingStatus in
							model.timeline.updateGap(id: gap.id, loadingStatus)
						} onRemove: {
							model.timeline.removeGap(id: gap.id)
						}
					case let .post(post):
						PostView(post: post, actionHandler: { _ in })
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.vertical, 6.0)
					}
				}
				.listStyle(PlainListStyle())
			}
		}
		.onChange(of: accountStore.accounts, initial: true) { _, newValue in
			model.updateAccounts(newValue)
		}
		.menuRefreshable {
			await model.refresh()
		}
//		.task(id: model.accountsIdentifier) {
//			await model.refresh()
//		}
	}
}

#Preview {
	Text("Feed View")
}
