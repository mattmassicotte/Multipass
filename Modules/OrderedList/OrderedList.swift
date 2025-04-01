import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public struct OrderedList<Content: View, Item: Hashable & Sendable> {
	@Environment(\.refresh) private var refreshAction
	
	private let items: [Item]
	private let content: (Item) -> Content
	
	public init(
		items: [Item],
		@ViewBuilder content: @escaping (Item) -> Content
	) {
		self.items = items
		self.content = content
	}
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
extension OrderedList : NSViewControllerRepresentable {
	public typealias NSViewControllerType = TableViewController<Content, Item>
	
	public func makeNSViewController(context: Context) -> NSViewControllerType {
		TableViewController(items: items, content: content)
	}
	
	public func updateNSViewController(_ viewController: NSViewControllerType, context: Context) {
		viewController.items = items
		viewController.refreshAction = refreshAction
	}
}
#elseif canImport(UIKit)
extension OrderedList : UIViewControllerRepresentable {
	public typealias UIViewControllerType = TableViewController<Content, Item>
	
	public func makeUIViewController(context: Context) -> TableViewController<Content, Item> {
		TableViewController(items: items, content: content)
	}
	
	public func updateUIViewController(_ viewController: TableViewController<Content, Item>, context: Context) {
		viewController.items = items
		viewController.refreshAction = refreshAction
	}
}

#endif
