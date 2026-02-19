//
//  GapLoadingBackground.swift
//  Timeline
//
//  Created by Ryan Lintott on 2026-02-17.
//

import SwiftUI

struct GapLoadingBackground: View {
	let color: Color
	let loadedOldestProgress: CGFloat
	let loadedNewestProgress: CGFloat
	let animation: Animation
	
	init(
		color: Color,
		loadedOldestProgress: CGFloat,
		loadedNewestProgress: CGFloat,
		animation: Animation = .default
	) {
		self.color = color
		self.loadedOldestProgress = loadedOldestProgress
		self.loadedNewestProgress = loadedNewestProgress
		self.animation = animation
	}
	
    var body: some View {
		Color.clear
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.overlay(alignment: .bottom) {
				color
					.alignmentGuide(.bottom) { d in
						d[.top] + d.height * loadedOldestProgress
					}
					.animation(animation, value: loadedOldestProgress)
			}
			.overlay(alignment: .top) {
				color
					.alignmentGuide(.top) { d in
						d[.bottom] - d.height * loadedNewestProgress
					}
					.animation(animation, value: loadedNewestProgress)
			}
			.clipped()
    }
}

extension GapLoadingBackground {
	init(gap: Gap, color: Color) {
		self.init(
			color: color,
			loadedOldestProgress: gap.loadedOldestProgress,
			loadedNewestProgress: gap.loadedNewestProgress
		)
	}
}


#Preview {
	@Previewable @State var loadedNewestProgress: CGFloat = 0
	@Previewable @State var loadedOldestProgress: CGFloat = 0
	
	VStack {
		Color.red.frame(height: 100)
		
		Text("Gap")
			.onTapGesture {
				if loadedNewestProgress < 1 {
					loadedOldestProgress = 1
					loadedNewestProgress = 1
				} else {
					loadedOldestProgress = 0
					loadedNewestProgress = 0
				}
			}
			.frame(maxWidth: .infinity, maxHeight: 100)
			.background(
				GapLoadingBackground(
					color: .blue,
					loadedOldestProgress: loadedOldestProgress,
					loadedNewestProgress: loadedNewestProgress
				)
			)
		
		Color.red.frame(height: 100)
	}
	
	
}
