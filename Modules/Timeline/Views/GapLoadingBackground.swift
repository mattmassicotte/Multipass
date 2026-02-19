//
//  GapLoadingBackground.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-02-17.
//

import SwiftUI

struct GapLoadingBackground: View {
	let color: Color
	let loadedOldest: CGFloat
	let loadedNewest: CGFloat
	let animation: Animation
	
	init(
		color: Color,
		loadedOldest: CGFloat,
		loadedNewest: CGFloat,
		animation: Animation = .default
	) {
		self.color = color
		self.loadedOldest = loadedOldest
		self.loadedNewest = loadedNewest
		self.animation = animation
	}
	
    var body: some View {
		Color.clear
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.overlay(alignment: .bottom) {
				color
					.alignmentGuide(.bottom) { d in
						d[.top] + d.height * loadedOldest
					}
					.animation(animation, value: loadedOldest)
			}
			.overlay(alignment: .top) {
				color
					.alignmentGuide(.top) { d in
						d[.bottom] - d.height * loadedNewest
					}
					.animation(animation, value: loadedNewest)
			}
			.clipped()
    }
}

extension GapLoadingBackground {
	init(gap: Gap, color: Color) {
		self.init(
			color: color,
			loadedOldest: gap.loadedOldestProgress,
			loadedNewest: gap.loadedNewestProgress
		)
	}
}


#Preview {
	@Previewable @State var loadedNewest: CGFloat = 0
	@Previewable @State var loadedOldest: CGFloat = 0
	
	VStack {
		Color.red.frame(height: 100)
		
		Text("Gap")
			.onTapGesture {
				if loadedNewest < 1 {
					loadedOldest = 1
					loadedNewest = 1
				} else {
					loadedOldest = 0
					loadedNewest = 0
				}
			}
			.frame(maxWidth: .infinity, maxHeight: 100)
			.background(GapLoadingBackground(color: .blue, loadedOldest: loadedOldest, loadedNewest: loadedNewest))
		
		Color.red.frame(height: 100)
	}
	.listRowSpacing(0)
	.listRowInsets(.all, 0)
	.listRowSeparator(.hidden)
	
	
}
