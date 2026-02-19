//
//  GapRevealButton.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-02-17.
//

import SwiftUI

struct GapRevealButton: View {
	let gapID: Gap.ID
	let range: Range<Date>
	let anchor: TemporalEdge
	let action: (Gap.Action) -> Void
	
	var duration: TimeInterval {
		range.duration
	}
	
	@ViewBuilder
	var menuButtons: some View {
		if duration > .hours(2) {
			#if os(macOS)
			#else
			Button {
				showNewest()
			} label: {
				Text("All")
			}
			#endif
		
			Section {
				ForEach([1, 2, 3], id: \.self) { hours in
					if duration > .hours(hours + 1) {
						Button {
							showNewest(hours: hours)
						} label: {
							Text(Measurement(value: Double(hours), unit: UnitDuration.hours), format: .measurement(width: .wide))
						}
					}
				}
			} header: {
				Text("Show Latest")
			}
			
			if anchor == .oldest {
				Section {
					ForEach([1, 2, 3], id: \.self) { hours in
						if duration > .hours(hours + 1) {
							Button {
								showOldest(hours: hours)
							} label: {
								Text(Measurement(value: Double(hours), unit: UnitDuration.hours), format: .measurement(width: .wide))
							}
						}
					}
				} header: {
					Text("Show Oldest")
				}
			}
		}
	}
	
	var body: some View {
		Menu {
			menuButtons
		} label: {
			Label {
				Text("Show All")
			} icon: {
				switch anchor {
				case .oldest:
					Image(systemName: "arrow.up")
				case .newest:
					Image(systemName: "arrow.down")
				}
			}
			.padding(4)
		} primaryAction: {
			showNewest()
		}
		.menuOrder(.fixed)
		#if os(macOS)
		.labelStyle(.titleAndIcon)
		#else
		.labelStyle(.iconOnly)
		#endif
		.buttonStyle(.glass)
	}
	
	func showOldest(hours: Int) {
		let date = Calendar.current.date(byAdding: .hour, value: hours, to: range.lowerBound) ?? range.lowerBound.addingTimeInterval(Double(3600 * hours))
		
		action(
			.reveal(
				gapID: gapID,
				fromEdge: .oldest,
				toDate: date,
				anchor: anchor
			)
		)
	}
	
	func showNewest(hours: Int? = nil) {
		guard let hours else {
			action(
				.reveal(
					gapID: gapID,
					fromEdge: .newest,
					anchor: anchor
				)
			)
			return
		}
		
		let date = range.upperBound.addingTimeInterval(Double(.hours(-hours)))
		
		action(
			.reveal(
				gapID: gapID,
				fromEdge: .newest,
				toDate: date,
				anchor: anchor
			)
		)
	}
}

extension GapRevealButton {
	init(gap: Gap, anchor: TemporalEdge, action: @escaping (Gap.Action) -> Void) {
		self.init(
			gapID: gap.id,
			range: gap.range,
			anchor: anchor,
			action: action
		)
	}
}

#Preview {
	HStack {
		GapRevealButton(
			gapID: UUID(),
			range: .latest(.hours(5)),
			anchor: .newest,
			action: { _ in }
		)
		
		Text("Gap: 5 hours")
			.frame(maxWidth: .infinity)
		
		GapRevealButton(
			gapID: UUID(),
			range: .latest(.hours(3.5)),
			anchor: .oldest,
			action: { _ in }
		)
	}
	.padding()
}
