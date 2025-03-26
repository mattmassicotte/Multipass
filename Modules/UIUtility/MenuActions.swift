import SwiftUI

extension FocusedValues {
	public typealias Action = () -> Void
	
	@Entry public var refreshAction: Action?
}
