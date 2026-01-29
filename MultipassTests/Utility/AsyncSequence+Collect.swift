extension AsyncSequence {
	func collect() async throws -> [Element] {
		var entries = [Element]()

		for try await entry in self {
			entries.append(entry)
		}

		return entries
	}
}
