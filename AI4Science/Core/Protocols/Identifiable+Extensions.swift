import Foundation

/// Extension to provide default Identifiable implementation
public extension Identifiable {
    /// Get a unique string representation of the identifier
    var idString: String {
        String(describing: id)
    }
}

/// Protocol for entities that can be compared by ID
public protocol IDComparable: Identifiable {
    /// Compare two entities by their IDs
    func isSame(as other: Self) -> Bool
}

public extension IDComparable {
    func isSame(as other: Self) -> Bool {
        self.id == other.id
    }
}

