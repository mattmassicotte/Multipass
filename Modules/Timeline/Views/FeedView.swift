import CompositeSocialService
import StableView
import Storage
import SwiftUI
import UIUtility

public struct FeedView: View {
	@Environment(UserAccountStore.self) private var accountStore
	@Environment(\.openURL) private var openURL
	
	@State private var model: FeedViewModel
	@State private var scrollPosition = ScrollPosition(idType: CompositeTimeline.Element.ID.self)

	public init(secretStore: SecretStore, timelineStore: TimelineStore) {
		self._model = State(
			wrappedValue: FeedViewModel(
				secretStore: secretStore,
				timelineStore: timelineStore
			)
		)
	}
	
	var scrollPositionItem: CompositeTimeline.Element? {
		guard let id = scrollPosition.viewID(type: CompositeTimeline.Element.ID.self) else {
			return nil
		}
		return model.timeline.elements[id]
	}

	public var body: some View {
		VStack {
			Button {
				Task {
					await model.refresh()
				}
			} label: {
				Text("Load Posts")
			}
			
			if !model.timeline.elements.isEmpty {
				ScrollView {
					ForEach(model.timeline.elements) { element in
						switch element {
						case let .gap(gap):
							GapView(gap: gap, action: gapAction)
						case let .post(post):
							PostView(post: post, actionHandler: { _ in })
								.frame(maxWidth: .infinity, alignment: .leading)
								.padding(.vertical, 6.0)
						}
					}
				}
				.scrollTargetLayout()
				.scrollPosition($scrollPosition)
				.defaultScrollAnchor(.top)
			}
			
			if let scrollPositionItem {
				Text("Scroll Position")
				switch scrollPositionItem {
				case .post(let post):
					Text("Post")
					Text(post.date, style: .time)
				case .gap(let gap):
					Text("Gap")
					Text(gap.range.lowerBound, style: .time)
				}
			}
		}
		.onChange(of: accountStore.accounts, initial: true) { _, newValue in
			model.updateAccounts(newValue)
		}
//		.menuRefreshable {
//			await model.refresh()
//		}
//		.task(id: model.accountsIdentifier) {
//			await model.refresh()
//		}
	}
	
	func gapAction(_ action: Gap.Action) -> Void {
		switch action {
		case let .fill(_, direction), let .remove(_, direction: direction):
			let scrollToElement: CompositeTimeline.Element?
			switch direction {
			case .newestFirst:
				scrollToElement = model.timeline.elements.lastBefore(id: .gap(action.gapID))
			case .oldestFirst:
				scrollToElement = model.timeline.elements.firstAfter(id: .gap(action.gapID))
			}
			if let scrollToElement {
				scrollTo(id: scrollToElement.id)
			}
		case .cancel:
			break
		}
		
		model.gapAction(action)
	}
	
	func scrollTo(id: CompositeTimeline.Element.ID) {
		scrollPosition.scrollTo(id: id, anchor: .center)
	}
}

#Preview {
	Text("Feed View")
}
