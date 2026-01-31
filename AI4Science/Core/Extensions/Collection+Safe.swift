import Foundation

extension Collection {
    /// Safe subscript with optional return
    public subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Array {
    /// Get element at index safely
    public func element(at index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }

    /// Get first N elements
    public func first(_ n: Int) -> [Element] {
        Array(prefix(n))
    }

    /// Get last N elements
    public func last(_ n: Int) -> [Element] {
        Array(suffix(n))
    }

    /// Check if index exists
    public func isValidIndex(_ index: Int) -> Bool {
        index >= 0 && index < count
    }

    /// Remove element safely
    @discardableResult
    public mutating func removeElement(at index: Int) -> Element? {
        guard isValidIndex(index) else { return nil }
        return remove(at: index)
    }

    /// Insert element safely
    public mutating func insertSafely(_ element: Element, at index: Int) {
        let validIndex = max(0, min(index, count))
        insert(element, at: validIndex)
    }

    /// Chunk array into smaller arrays
    public func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }

    /// Get random element
    public var randomElement: Element? {
        isEmpty ? nil : randomElement()
    }

    /// Remove all instances of element
    public mutating func removeAll(where element: Element) where Element: Equatable {
        removeAll { $0 == element }
    }

    /// Check if array contains all elements
    public func containsAll<S: Sequence>(_ elements: S) -> Bool where Element: Equatable, S.Element == Element {
        elements.allSatisfy { contains($0) }
    }

    /// Filter to unique elements
    public var unique: [Element] where Element: Hashable {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }

    /// Transpose 2D array
    public func transposed() -> [[Element]] where Element: Sequence {
        guard let first = self.first else { return [] }
        let count = first.count
        return (0 ..< count).map { index in
            compactMap { Array($0)[safe: index] }
        }
    }
}

extension Sequence {
    /// Group elements by key
    public func groupedBy<Key: Hashable>(_ keyPath: KeyPath<Element, Key>) -> [Key: [Element]] {
        Dictionary(grouping: self, by: { $0[keyPath: keyPath] })
    }

    /// Map to dictionary
    public func toDictionary<Key: Hashable>(_ keyPath: KeyPath<Element, Key>) -> [Key: Element] {
        Dictionary(uniqueKeysWithValues: map { ($0[keyPath: keyPath], $0) })
    }
}
