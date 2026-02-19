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
			ScrollView {
				LazyVStack(spacing: 0) {
					Divider()
					
					ForEach(model.timeline.elements) { element in
						switch element {
						case let .gap(gap):
							GapView(gap: gap, action: gapAction)
						case let .post(post):
							PostView(post: post, action: model.postAction)
						}
						
						Divider()
					}
					
					TimelineLoadingButton(action: model.timelineAction)
						.frame(maxWidth: .infinity)
						.padding()
				}
			}
			.scrollTargetLayout()
			.scrollPosition($scrollPosition)
			.defaultScrollAnchor(.top)
			
			VStack {
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
			.border(.red)
		}
		.onChange(of: accountStore.accounts, initial: true) { _, newValue in
			model.updateAccounts(newValue)
		}
		.menuRefreshable {
			model.timelineAction(.loadRecent(maxTimeInterval: .hours(2)))
		}
//		.task(id: model.accountsIdentifier) {
//			await model.refresh()
//		}
	}
	
	func gapAction(_ action: Gap.Action) -> Void {
		switch action {
		case .fill, .cancel:
			break
		case let .reveal(id, fromEdge, toDate, anchor):
			let scrollToID: CompositeTimeline.Element.ID?
			switch (fromEdge, toDate, anchor) {
			case (_, nil, .oldest), (.newest, _, .newest):
				scrollToID = model.timeline.elements.lastBefore(id: .gap(id))?.id
			case (_, nil, .newest), (.oldest, _, .oldest):
				scrollToID = model.timeline.elements.firstAfter(id: .gap(id))?.id
			case (.newest, _, .oldest), (.oldest, _, .newest):
				scrollToID = .gap(id)
			}
			if let scrollToID {
				scrollTo(id: scrollToID)
			}
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
