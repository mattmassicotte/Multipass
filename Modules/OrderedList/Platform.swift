import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

typealias TableViewDiffableDataSource = NSTableViewDiffableDataSource
public typealias ViewController = NSViewController
public typealias TableView = NSTableView

extension TableViewDiffableDataSource {
	convenience init(
		tableView: NSTableView,
		cellProvider: @escaping (NSTableView, Int, ItemIdentifierType) -> NSView
	) {
		self.init(tableView: tableView) { tableView, _, row, item in
			cellProvider(tableView, row, item)
		}
	}
}

extension TableView {
	func dequeueHostingCell<Content: View>(identifier: String, content: () -> Content) -> NSView {
		NSHostingView(rootView: content())
	}
}

#elseif canImport(UIKit)
import UIKit

typealias TableViewDiffableDataSource = UITableViewDiffableDataSource
public typealias ViewController = UIViewController
public typealias TableView = UITableView

extension TableView {
	func dequeueHostingCell<Content: View>(identifier: String, content: () -> Content) -> UITableViewCell {
		let cell = dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell()
		
		cell.contentConfiguration = UIHostingConfiguration(content: content)
		
		return cell
	}
}

#endif

