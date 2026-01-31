import Foundation
import SwiftData

/// Protocol for local data source operations
protocol LocalDataSourceProtocol: Sendable {
    associatedtype Model

    func create(_ model: Model) async throws
    func read(id: String) async throws -> Model?
    func update(_ model: Model) async throws
    func delete(id: String) async throws
    func readAll() async throws -> [Model]
}

/// Base local data source implementation
actor LocalDataSource<T: PersistentModel & Identifiable>: LocalDataSourceProtocol where T.ID == String {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Create new model
    func create(_ model: T) async throws {
        modelContext.insert(model)
        try modelContext.save()
    }

    /// Read model by ID
    func read(id: String) async throws -> T? {
        let descriptor = FetchDescriptor<T>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Update model
    func update(_ model: T) async throws {
        try modelContext.save()
    }

    /// Delete model by ID
    func delete(id: String) async throws {
        guard let model = try read(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(model)
        try modelContext.save()
    }

    /// Read all models
    func readAll() async throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try modelContext.fetch(descriptor)
    }

    /// Clear all data
    func clearAll() async throws {
        let descriptor = FetchDescriptor<T>()
        let models = try modelContext.fetch(descriptor)
        for model in models {
            modelContext.delete(model)
        }
        try modelContext.save()
    }

    /// Get count of all models
    func count() async throws -> Int {
        let descriptor = FetchDescriptor<T>()
        let models = try modelContext.fetch(descriptor)
        return models.count
    }
}

/// User local data source
actor UserLocalDataSource: LocalDataSourceProtocol {
    typealias Model = UserEntity

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(_ model: UserEntity) async throws {
        modelContext.insert(model)
        try modelContext.save()
    }

    func read(id: String) async throws -> UserEntity? {
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func update(_ model: UserEntity) async throws {
        try modelContext.save()
    }

    func delete(id: String) async throws {
        guard let user = try read(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(user)
        try modelContext.save()
    }

    func readAll() async throws -> [UserEntity] {
        let descriptor = FetchDescriptor<UserEntity>()
        return try modelContext.fetch(descriptor)
    }
}

/// Project local data source
actor ProjectLocalDataSource: LocalDataSourceProtocol {
    typealias Model = ProjectEntity

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(_ model: ProjectEntity) async throws {
        modelContext.insert(model)
        try modelContext.save()
    }

    func read(id: String) async throws -> ProjectEntity? {
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func update(_ model: ProjectEntity) async throws {
        try modelContext.save()
    }

    func delete(id: String) async throws {
        guard let project = try read(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(project)
        try modelContext.save()
    }

    func readAll() async throws -> [ProjectEntity] {
        let descriptor = FetchDescriptor<ProjectEntity>()
        return try modelContext.fetch(descriptor)
    }
}

/// Capture local data source
actor CaptureLocalDataSource: LocalDataSourceProtocol {
    typealias Model = CaptureEntity

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(_ model: CaptureEntity) async throws {
        modelContext.insert(model)
        try modelContext.save()
    }

    func read(id: String) async throws -> CaptureEntity? {
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func update(_ model: CaptureEntity) async throws {
        try modelContext.save()
    }

    func delete(id: String) async throws {
        guard let capture = try read(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(capture)
        try modelContext.save()
    }

    func readAll() async throws -> [CaptureEntity] {
        let descriptor = FetchDescriptor<CaptureEntity>()
        return try modelContext.fetch(descriptor)
    }
}
