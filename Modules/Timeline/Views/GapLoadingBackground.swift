//
//  GapLoadingBackground.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-02-17.
//

import SwiftUI

struct GapLoadingBackground: View {
	let loadedOldest: CGFloat
	let loadedNewest: CGFloat
	let animation: Animation
	
	init(loadedOldest: CGFloat, loadedNewest: CGFloat, animation: Animation = .default) {
		self.loadedOldest = loadedOldest
		self.loadedNewest = loadedNewest
		self.animation = animation
	}
	
    var body: some View {
		Color.clear
			.overlay(alignment: .bottom) {
				Rectangle()
					.fill(.background)
					.containerRelativeFrame(.vertical) { length, _ in
						length * loadedOldest
					}
					.animation(animation, value: loadedOldest)
			}
			.overlay(alignment: .top) {
				Rectangle()
					.fill(.background)
					.containerRelativeFrame(.vertical) { length, _ in
						length * loadedNewest
					}
					.animation(animation, value: loadedNewest)
			}
    }
}

extension GapLoadingBackground {
	init(gap: Gap) {
		self.init(loadedOldest: gap.loadedOldestProgress, loadedNewest: gap.loadedNewestProgress)
	}
}


#Preview {
	@Previewable @State var loadedNewest: CGFloat = 0
	@Previewable @State var loadedOldest: CGFloat = 0
	
	List {
		Color.red.frame(height: 100)
		
		Color.blue
			.onTapGesture {
				if loadedNewest < 1 {
					loadedOldest = 1
					loadedNewest = 1
				} else {
					loadedOldest = 0
					loadedNewest = 0
				}
			}
			.frame(height: 100)
			.listRowBackground(GapLoadingBackground(loadedOldest: loadedOldest, loadedNewest: loadedNewest))
		
		Color.red.frame(height: 100)
	}
	.listRowSpacing(0)
	.listRowInsets(.all, 0)
	.listRowSeparator(.hidden)
	
	
}
