import Foundation

import CompositeSocialService

public class TimelineModel {
	public enum ServiceState: Sendable {
		case idle
		case loading(Date)
		case error(Error)
	}

	public typealias TimelineCompositor = ([AccountTimeline]) async throws -> CompositeTimeline
	public typealias FillProgress = (Int, ServiceState) -> Void

	typealias LoadingProgress = (Int, ServiceState) -> Void

	private var timelines: [AccountTimeline]
	private var resolutionTask: Task<Void, any Error>?

	public var visibleRange: Range<Date>
	public let services: [any SocialService]
	public private(set) var timeline = CompositeTimeline()
	public var compositor: TimelineCompositor
	public var timelineHandler: (CompositeTimeline) -> Void = { _ in }

	public init(
		services: [any SocialService]
	) {
		self.services = services
		self.visibleRange = Date.now..<Date.now
		self.compositor = Self.simpleCompositor
		self.timelines = services.map { AccountTimeline(id: $0.id) }
	}

	public init(
		pairedServices: [(any SocialService, [AccountTimeline.Element])],
	) {
		self.services = pairedServices.map { $0.0 }
		self.visibleRange = Date.now..<Date.now
		self.compositor = Self.simpleCompositor
		self.timelines = pairedServices.map { AccountTimeline(id: $0.0.id, $0.1) }
	}

	public func fill(gap: Range<Date>, progress: @escaping FillProgress, isolation: isolated any Actor = #isolation) async {
		let sequences = services.map { $0.timeline(within: gap, isolation: isolation) }

		// a TaskGroup would be way better, but I need the isolated param
		let tasks = zip(sequences, sequences.indices).map {
			sequence,
			index in
			progress(index, .loading(gap.upperBound))
			
			let task = Task<Void, Never> {
				_ = isolation
				
				await loadPosts(
					in: sequence,
					dateLimit: gap.lowerBound,
					for: index,
					progress: progress
				)
			}

			return task
		}

		await withTaskCancellationHandler {
			for task in tasks {
				_ = await task.value
			}
		} onCancel: {
			for task in tasks {
				task.cancel()
			}
		}
	}

	private func loadPosts(
		in sequence: some AsyncSequence<TimelineFragment, any Error>,
		dateLimit: Date,
		for index: Int,
		progress: @escaping FillProgress,
		isolation: isolated any Actor = #isolation
	) async {
		do {
			for try await fragment in sequence {
				self.timelines[index].merge(
					dateLimit: dateLimit,
					fragment
				)

				try resolveUnifiedTimeline()
			}

			progress(index, .idle)
		} catch {
			progress(index, .error(error))
		}
	}
}

extension TimelineModel {
	private func resolveUnifiedTimeline(isolation: isolated any Actor = #isolation) throws {
		let pending = resolutionTask

		let task = Task {
			_ = isolation

			try await pending?.value

			// resolve

			let timeline = try await compositor(timelines)

			timelineHandler(timeline)
		}

		self.resolutionTask = task
	}

	public static func simpleCompositor(timelines: [AccountTimeline]) async -> CompositeTimeline {
		CompositeTimeline(timelines: timelines, idProvider: { _, _ in UUID() })
	}
}
