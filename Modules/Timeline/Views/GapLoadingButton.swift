//
//  GapLoadingButton.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-02-17.
//

import SwiftUI

struct GapLoadingButton: View {
	let gap: Gap
	let direction: Gap.OpeningDirection
	let action: (Gap.Action) -> Void
	
    var body: some View {
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
			primaryAction()
		}
		.menuOrder(.fixed)
		.labelStyle(.iconOnly)
    }
	
	func primaryAction() {
		switch gap.loadingStatus {
		case .unloaded, .paused, .error:
			action(.fill(gap.id, direction: direction))
		case .loading:
			action(.cancel(gap.id))
		case .loaded:
			action(.remove(gap.id, direction: direction))
		}
	}
}

#Preview {
	GapLoadingButton(gap: .example(), direction: .oldestFirst) { _ in }
	
	GapLoadingButton(gap: .example(), direction: .oldestFirst) { _ in }
	
	GapLoadingButton(gap: .example(), direction: .oldestFirst) { _ in }
}
