import SwiftUI

@MainActor @Observable
public final class MenuActions {
	public typealias Handler = @MainActor () -> Void
	
	public var refresh: Handler? = nil
	
	public init() {
	}
}
