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
	
	var duration: String? {
		let componentsFormatter = DateComponentsFormatter()
		componentsFormatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
		componentsFormatter.unitsStyle = .brief
		componentsFormatter.maximumUnitCount = 2

		return componentsFormatter.string(from: gap.range.lowerBound, to: gap.range.upperBound)
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
			GapLoadingButton(gap: gap, direction: .newestFirst, action: action)
			
			VStack {
				if let duration {
					Text("Gap: \(duration)")
					Text(gap.loadingStatus.rawValue)
					
				} else {
					Text("Gap")
				}
			}
			.frame(maxWidth: .infinity)
			
			GapLoadingButton(gap: gap, direction: .oldestFirst, action: action)
		}
		.padding(.horizontal)
		.frame(maxWidth: .infinity)
		.accentColor(.pink)
		.background(Color.gray)
		.listRowBackground(GapLoadingBackground(gap: gap))
    }
}

#Preview {
	@Previewable @State var gap: Gap? = .example(range: Date()..<Date().addingTimeInterval(10000))
	
	VStack(alignment: .leading) {
		PostView(post: .placeholder) { _ in }
		if let thisGap = gap {
			GapView(gap: thisGap) { action in
				switch action {
				case .fill:
					gap?.isLoading = true
				case .cancel:
					break
				case .remove:
					gap = nil
				}
			}
		} else {
			Button("Add gap") {
				gap = .example(range: Date()..<Date().addingTimeInterval(10000))
			}
		}
		PostView(post: .placeholder) { _ in }
	}
}

