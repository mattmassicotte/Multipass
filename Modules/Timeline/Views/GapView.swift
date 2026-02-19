//
//  GapView.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-01-30.
//

import SwiftUI

struct GapView: View {
	let gap: Gap
	let action: (Gap.Action) -> Void
	
	static let formatter: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
		formatter.unitsStyle = .brief
		formatter.maximumUnitCount = 2
		return formatter
	}()
	
	var duration: String? {
		Self.formatter.string(from: gap.range.lowerBound, to: gap.range.upperBound)
	}
	
	func rangeView(_ range: Range<Date>, label: String = "Range") -> some View {
		Text("\(label): \(range.lowerBound, format: .dateTime.hour().minute().second()) - \(range.upperBound, format: .dateTime.hour().minute().second())")
	}
	
	var debugInfo: some View {
		VStack {
			rangeView(gap.range)
			if let concealedRange = gap.concealedRange {
				rangeView(concealedRange, label: "Concealed")
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
	}
	
    var body: some View {
		HStack {
			if gap.loadingStatus == .loaded {
				GapRevealButton(gap: gap, anchor: .newest, action: action)
			}
			
			VStack {
				if let duration {
					Text("Gap: \(duration)")
				} else {
					Text("Gap")
				}
				Label {
					switch gap.loadingStatus {
					case .unloaded:
						Text("Load")
					case .loading:
						Text("Loading...")
					case .paused:
						Text("Paused")
					case .loaded:
						Text("Loaded")
					case .error:
						Text("Error: \(gap.error?.localizedDescription, default: "Unknown error")")
					}
				} icon: {
					switch gap.loadingStatus {
					case .unloaded:
						EmptyView()
					case .loading:
						Image(systemName: "arrow.trianglehead.2.clockwise")
							.symbolEffect(.rotate)
					case .paused:
						Image(systemName: "pause")
					case .loaded:
						Image(systemName: "checkmark")
					case .error:
						Image(systemName: "exclamationmark.triangle")
					}
				}
			}
			.frame(maxWidth: .infinity)
			
			if gap.loadingStatus == .loaded {
				GapRevealButton(gap: gap, anchor: .oldest, action: action)
			}
		}
		.onTapGesture {
			switch gap.loadingStatus {
			case .unloaded, .paused, .error:
				action(.fill(gap.id))
			case .loading:
				action(.cancel(gap.id))
			case .loaded:
				break
			}
		}
		.padding(.horizontal)
		.frame(maxWidth: .infinity)
		.accentColor(.pink)
		.background(GapLoadingBackground(gap: gap, color: .gray))
    }
}

#Preview {
	VStack(spacing: 0) {
		Divider()
		
		GapView(
			gap: Gap.example(
				range: .latest(.hours(2)),
				serviceIDs: ["1"],
				loadedRanges: ["1": [.latest(.hours(1))]],
				isLoading: true
			)
		) { _ in }
		
		Divider()
		
		GapView(
			gap: Gap.example(
				range: .latest(.hours(2)),
				serviceIDs: ["1"],
				loadedRanges: ["1": [.latest(.hours(1))]],
				isLoading: false
			)
		) { _ in }
		
		Divider()
		
		GapView(
			gap: Gap.example(
				range: .latest(.hours(2)),
				serviceIDs: ["1"],
				loadedRanges: ["1": [.latest(.hours(1))]],
				isLoading: true,
				error: .gapAlreadyBeingFilled(id: UUID())
			)
		) { _ in }
		
		Divider()
		
		GapView(
			gap: Gap.example(
				range: .latest(.hours(2)),
				serviceIDs: ["1"],
				loadedRanges: ["1": [.latest(.hours(2))]],
				isLoading: false
			)
		) { _ in }
		
		Divider()
	}
}

