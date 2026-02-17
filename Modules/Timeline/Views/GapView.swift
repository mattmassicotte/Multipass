//
//  GapView.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-01-30.
//

import SwiftUI

struct GapView: View {
	let gap: Gap
	
	let updateLoadingStatus: (Gap.LoadingStatus) -> Void
	let onRemove: () -> Void
	
	var duration: String? {
		let componentsFormatter = DateComponentsFormatter()
		componentsFormatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
		componentsFormatter.unitsStyle = .brief
		componentsFormatter.maximumUnitCount = 2

		return componentsFormatter.string(from: gap.range.lowerBound, to: gap.range.upperBound)
	}
	
	func testLoadingButton() -> some View {
		Button {
			switch gap.loadingStatus {
			case .unloaded:
				updateLoadingStatus(.loading)
			case .loading:
				updateLoadingStatus(.paused)
			case .paused:
				updateLoadingStatus(.loading)
			case .error:
				updateLoadingStatus(.loading)
			case .loaded:
				onRemove()
			}
		} label: {
			switch gap.loadingStatus {
			case .unloaded:
				Label("Download", systemImage: "arrow.trianglehead.clockwise.icloud")
			case .loading:
				ProgressView()
			case .paused:
				Label("Download", systemImage: "pause")
			case .error:
				Label("Restart", systemImage: "exclamationmark.triangle")
			case .loaded:
				Label {
					Text("Show Posts")
				} icon: {
					Image(systemName: "arrow.down")
				}
			}
		}
	}
	
	func loadingButton(direction: Gap.OpeningDirection) -> some View {
		Menu {
			switch direction {
			case .oldestFirst:
				Button {
					
				} label: {
					Text("All")
				}
				
				Menu {
					Button {
						
					} label: {
						Text("1 hour")
					}
					
					Button {
						
					} label: {
						Text("3 hours")
					}
				} label: {
					Label("Skip", systemImage: "chevron.up.2")
				}
				
				Menu {
					Button {
						
					} label: {
						Text("1 hours")
					}
					
					Button {
						
					} label: {
						Text("3 hours")
					}
				} label: {
					Label("Show latest", systemImage: "arrow.down.to.line")
				}
				
				
			case .newestFirst:
				Button {
					
				} label: {
					Text("3 hours")
				}
				
				Button {
					
				} label: {
					Text("6 hours")
				}
				
				Button {
					
				} label: {
					Text("All")
				}
			}
		} label: {
			Label {
				switch direction {
				case .oldestFirst:
					Text("Oldest")
				case .newestFirst:
					Text("Newest")
				}
			} icon: {
				switch gap.loadingStatus {
				case .unloaded:
					Image(systemName: "arrow.trianglehead.clockwise.icloud")
				case .loading:
					ProgressView()
				case .paused:
					Image(systemName: "pause")
				case .loaded:
					switch direction {
					case .oldestFirst:
						Image(systemName: "arrow.up")
					case .newestFirst:
						Image(systemName: "arrow.down")
					}
				case .error:
					Image(systemName: "exclamationmark.triangle")
				}
			}
		} primaryAction: {
			switch gap.loadingStatus {
			case .unloaded:
				updateLoadingStatus(.loading)
			case .loading:
				updateLoadingStatus(.paused)
			case .paused:
				updateLoadingStatus(.loading)
			case .error:
				updateLoadingStatus(.loading)
			case .loaded:
				onRemove()
			}
		}
		.menuOrder(.fixed)
	}
	
	func rangeView(_ range: Range<Date>, label: String = "Range") -> some View {
		Text("\(label): \(range.lowerBound, format: .dateTime.hour().minute().second()) - \(range.upperBound, format: .dateTime.hour().minute().second())")
	}
	
    var body: some View {
		VStack {
			if let duration {
				Text("Gap: \(duration)")
				Text(gap.loadingStatus.rawValue)
				rangeView(gap.range)
				if let concealedRange = gap.concealedRange {
					rangeView(concealedRange, label: "Concealed")
				}
			}
			ForEach(gap.serviceIDs.sorted(), id: \.self) { serviceID in
				Text("\(serviceID)")
					.font(.headline)
				if let gapLoadedRange = gap.loadedRanges[serviceID] {
					ForEach(gapLoadedRange, id: \.self) { range in
						rangeView(range)
					}
				} else {
					Text("Empty")
				}
				
			}
		}
		.frame(maxWidth: .infinity)
		.padding(.horizontal)
//		.overlay(alignment: .topLeading) {
//			loadingButton(direction: .newestFirst)
//		}
		.overlay(alignment: .bottomTrailing) {
			testLoadingButton()
//			loadingButton(direction: .oldestFirst)
		}
		.accentColor(.pink)
		.background(Color.gray)
    }
}

#Preview {
	@Previewable @State var gap: Gap? = .example(range: Date()..<Date().addingTimeInterval(10000))
	
	VStack(alignment: .leading) {
		PostView(post: .placeholder) { _ in }
		if let thisGap = gap {
			GapView(gap: .example(range: Date()..<Date().addingTimeInterval(10000))) {
				gap?.loadingStatus = $0
			} onRemove: {
				gap = nil
			}
		} else {
			Button("Add gap") {
				gap = .example(range: Date()..<Date().addingTimeInterval(10000))
			}
		}
		PostView(post: .placeholder) { _ in }
	}
}

