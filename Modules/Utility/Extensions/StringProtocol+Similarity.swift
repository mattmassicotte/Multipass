extension StringProtocol {
	public func similarity(to other: some StringProtocol) -> Float {
		if isEmpty {
			return other.isEmpty ? 1.0 : 0.0
		}

		let diff = difference(from: other)
		let changes = Float(diff.insertions.count + diff.removals.count)
		let total = Float(count) * 2.0

		return (total - changes) / total
	}
}
