import Foundation
import SwiftData

/// Protocol for local data source operations
protocol LocalDataSourceProtocol {
    associatedtype Model: Sendable

    func create(_ model: Model) async throws
    func read(id: String) async throws -> Model?
    func update(_ model: Model) async throws
    func delete(id: String) async throws
    func readAll() async throws -> [Model]
}
