import Foundation

/// Protocol for entities with timestamps
public protocol Timestamped: Sendable {
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

/// Protocol for timestamped entities that can be identified
public protocol IdentifiableTimestamped: Identifiable, Timestamped where ID == UUID {}

/// Protocol combining common entity patterns
public protocol Entity: IdentifiableTimestamped, Codable, Equatable, Hashable {}
