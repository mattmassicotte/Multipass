import ATM
import LRUCache
import TaskGate

struct LRUCacheStore<Key: Hashable & Sendable, Value: Sendable>: BackingStore {
	private let lruCache = LRUCache<Key, CacheEntry<Value>>(clearsOnMemoryPressure: true)

	public func readEntry(_ key: Key) -> CacheEntry<Value>? {
		lruCache.value(forKey: key)
	}

	public func write(_ key: Key, _ value: Value?, cost: Int) {
		guard let value else {
			lruCache.removeValue(forKey: key)
			return
		}

		let entry = CacheEntry(value: value, cost: cost)

		lruCache.setValue(entry, forKey: key, cost: cost)
	}
}

/// A simple cache with an optional on-disk backing store.
public final class Cache<
	Key: Hashable & Sendable,
	Value: Sendable
> {
	private var backingCache: SynchronousCache<Key, Value>
	private let gate = AsyncGate()

	private init(cache: SynchronousCache<Key, Value>) {
		self.backingCache = cache
	}

	public init() {
		self.backingCache = SynchronousCache<Key, Value>(
			levels: [
				.init(writePolicy: .writeThrough, evictionPolicy: .age(2 * 60 * 60), store: LRUCacheStore<Key, Value>())
			]
	 )
	}

	public func readOrFill<Failure: Error>(
		_ key: Key,
		cost: Int = 0,
		fill: () async throws(Failure) -> Value
	) async throws(Failure) -> Value {
		return try await gate.withGate { () async throws(Failure) -> Value in
			if let value = readEntry(key) {
				return value.value
			}

			print("miss:", key)

			let value = try await fill()

			write(key, value, cost: cost)

			return value
		}
	}
}

extension Cache: BackingStore {
	public func readEntry(_ key: Key) -> CacheEntry<Value>? {
		backingCache.readEntry(key)
	}

	public func write(_ key: Key, _ value: Value?, cost: Int) {
		backingCache.write(key, value, cost: cost)
	}
}

extension Cache where Value: Codable {
	public convenience init(
		directoryURL: URL? = nil,
		keyEncoder: @escaping (Key) -> String
	) {
		var levels: [SynchronousCache<Key, Value>.CacheLevel] = [
			.init(writePolicy: .writeThrough, evictionPolicy: .age(2 * 60 * 60), store: LRUCacheStore<Key, Value>())
		 ]

		if let directoryURL {
			do {
				let fileSystemStore = try FileSystemBackingStore<Key, Value>(
					url: directoryURL,
					keyEncoder: keyEncoder
				)

				print("cache url:", directoryURL)

				let level = SynchronousCache<Key, Value>.CacheLevel(
					writePolicy: .writeThrough,
					evictionPolicy: .age(2 * 24 * 60 * 26),
					store: fileSystemStore
				)

				levels.append(level)
			} catch {
				print("unable to create on-disk cache at:", directoryURL, error)
			}
		}

		self.init(
			cache: SynchronousCache<Key, Value>(
				levels: levels
			)
		)
	}
}

extension Cache where Key: CustomStringConvertible, Value: Codable {
	public convenience init(
		directoryURL: URL
	) {
		self.init(
			directoryURL: directoryURL,
			keyEncoder: { $0.description }
		)
	}

	public convenience init(
		cachePath: String
	) {
		self.init(
			directoryURL: URL.cachesDirectory.appending(path: cachePath),
			keyEncoder: { $0.description }
		)
	}
}
