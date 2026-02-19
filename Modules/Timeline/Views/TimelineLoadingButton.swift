//
//  TimelineLoadingButton.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-02-18.
//

import SwiftUI

struct TimelineLoadingButton: View {
	let action: (CompositeTimeline.Action) -> Void
	
	let style = Duration.UnitsFormatStyle(
		allowedUnits: [.days, .hours],
		width: .wide,
		maximumUnitCount: 1
	)
	
    var body: some View {
		Menu {
			ForEach([1, 3, 6, 12], id: \.self) { hours in
				Button {
					loadOlder(.hours(hours))
				} label: {
					Text(Duration.hours(hours).formatted(style))
				}
			}
			
			ForEach([1, 2], id: \.self) { days in
				Button {
					loadOlder(.days(days))
				} label: {
					Text(Duration.days(days).formatted(style))
				}
			}
		} label: {
			Label("Load more...", systemImage: "arrow.down")
		}
		.menuOrder(.fixed)
		.buttonStyle(.glass)
    }
	
	func loadOlder(_ timeInterval: TimeInterval) {
		action(.loadOlder(timeInterval: timeInterval))
	}
}

#Preview {
	TimelineLoadingButton { _ in }
}
