//
//  GapView.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-01-30.
//

import SwiftUI

struct Gap {
	/// Unique ID created when gap is initialized
	let id: UUID
	/// A date range that defines the bounds of this gap
	var range: Range<Date>
	/// Loading status of the posts in this gap.
	var loadingStatus: LoadingStatus
	/// Read/Unread status of posts in this gap
	var readStatus: ReadStatus
	
	enum LoadingStatus {
		case unloaded
		case loading(unloaded: Range<Date>, isPaused: Bool, error: Error?)
		case loaded
	}
	
	enum ReadStatus {
		case unknown
		case unread
		case read
		case mixed
	}
	
	enum OpeningDirection {
		/// Opening direction that locks to the oldest post so the user can read posts chronologically
		case oldestFirst
		/// Opening direction that locks to the newest post so the user can read posts chronologically
		case newestFirst
	}
}

extension Gap {
	static func example(
		id: UUID = UUID(),
		range: Range<Date>,
		loadingStatus: LoadingStatus = .loaded,
		readStatus: ReadStatus = .unknown
	) -> Self {
		.init(
			id: id,
			range: range,
			loadingStatus: loadingStatus,
			readStatus: readStatus
		)
	}
}

struct GapView: View {
	@Binding var gap: Gap
	
	var duration: String? {
		let componentsFormatter = DateComponentsFormatter()
		componentsFormatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
		componentsFormatter.unitsStyle = .brief
		componentsFormatter.maximumUnitCount = 2

		return componentsFormatter.string(from: gap.range.lowerBound, to: gap.range.upperBound)
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
				case .loaded:
					switch direction {
					case .oldestFirst:
						Image(systemName: "arrow.up")
					case .newestFirst:
						Image(systemName: "arrow.down")
					}
				}
			}
		} primaryAction: {
			switch gap.loadingStatus {
			case .unloaded:
				gap.loadingStatus = .loading(unloaded: gap.range, isPaused: false, error: nil)
			case .loading:
				gap.loadingStatus = .loaded
			case .loaded:
				gap.loadingStatus = .unloaded
			}
		}
		.menuOrder(.fixed)
	}
	
    var body: some View {
		HStack {
			loadingButton(direction: .newestFirst)
				.frame(maxHeight: .infinity, alignment: .top)
		
			HStack {
				if let duration {
					Text("Gap: \(duration)")
				}
			}
			.frame(maxWidth: .infinity)
			
			loadingButton(direction: .oldestFirst)
				.frame(maxHeight: .infinity, alignment: .bottom)
		}
		.accentColor(.pink)
		.padding(.horizontal)
		.frame(maxWidth: .infinity, maxHeight: 60)
		.background(Color.gray)
    }
}

#Preview {
	@Previewable @State var gap: Gap = .example(range: Date()..<Date().addingTimeInterval(10000))
	
	VStack(alignment: .leading) {
		PostView(post: .placeholder) { _ in }
		GapView(gap: $gap)
		PostView(post: .placeholder) { _ in }
	}
}

