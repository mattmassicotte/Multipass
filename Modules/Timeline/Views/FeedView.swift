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
	
	static let loadingButtonID = CompositeTimeline.Element.ElementID.gap(UUID())
	
	var scrollPositionID: CompositeTimeline.Element.ElementID? {
		scrollPosition.viewID(type: CompositeTimeline.Element.ID.self)
	}
	var scrollPositionItem: CompositeTimeline.Element? {
		guard let scrollPositionID else { return nil }
		return model.timeline.elements[scrollPositionID]
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
					
					VStack {
						TimelineLoadingButton(action: model.timelineAction)
					}
					.frame(maxWidth: .infinity)
					.padding()
					.id(Self.loadingButtonID)
				}
				.scrollTargetLayout()
			}
			.scrollPosition($scrollPosition)
			.defaultScrollAnchor(.top)
			.overlay(alignment: .bottom) {
				VStack {
					if let scrollPositionItem {
						Text("Scroll Position")
						switch scrollPositionItem {
						case .post(let post):
							Text("Post")
							if let content = post.content {
								Text(content)
									.lineLimit(1)
							}
						case .gap(let gap):
							Text("Gap")
							Text(gap.range.lowerBound, style: .time)
						}
					} else if let scrollPositionID {
						if scrollPositionID == Self.loadingButtonID {
							Text("Loading Button")
						} else {
							Text("Unknown")
						}
					}
				}
				.font(.caption2)
				.border(.red)
			}
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
			case (_, nil, .newest), (.newest, _, .newest):
				scrollToID = model.timeline.elements.lastBefore(id: .gap(id))?.id
			case (_, nil, .oldest), (.oldest, _, .oldest):
				scrollToID = model.timeline.elements.firstAfter(id: .gap(id))?.id ?? Self.loadingButtonID
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
		if let element = model.timeline.elements[id] {
			print("Scroll to: \(element.debugDescription)")
		} else if id == Self.loadingButtonID {
			print("Scroll to: Loading button")
		}
		scrollPosition.scrollTo(id: id)
	}
}

#Preview {
	Text("Feed View")
}
