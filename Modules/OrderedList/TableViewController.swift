import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public final class TableViewController<Content: View, Item: Hashable & Sendable> : ViewController {
	typealias Section = Int
	
	private var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
	let tableView = TableView(frame: .zero)
	private let content: (Item) -> Content
	
	private lazy var dataSource: TableViewDiffableDataSource<Section, Item> = {
		TableViewDiffableDataSource<Section, Item>(tableView: tableView) { [content] tableView, path, item in
			tableView.dequeueHostingCell(identifier: "id") {
				content(item)
			}
		}
	}()
	
	public init(
		items: [Item],
		@ViewBuilder content: @escaping (Item) -> Content
	) {
		self.content = content
		self.items = items
		
		super.init(nibName: nil, bundle: nil)
		
		snapshot.appendSections([0])
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public var items: [Item] {
		didSet {
			snapshot.appendItems(items, toSection: 0)
			
			updateDataSource()
		}
	}
	
	public override func loadView() {
		tableView.dataSource = dataSource
		
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
		let column = NSTableColumn(identifier: .init("main"))
		
		tableView.addTableColumn(column)
		tableView.usesAutomaticRowHeights = true
		
		let scrollView = NSScrollView()
		
		scrollView.documentView = tableView
		
		self.view = scrollView
#elseif canImport(UIKit)
		self.view = tableView
#endif
		updateDataSource()
	}
	
	private func updateDataSource() {
		dataSource.apply(snapshot, animatingDifferences: true)
	}
}
