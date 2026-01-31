//
//  ProjectRepositoryTests.swift
//  AI4ScienceTests
//
//  Extended repository tests for findAll, search, and delete edge cases.
//

import Testing
import Foundation
import SwiftData
@testable import AI4Science

@Suite("Project Repository Extended Tests")
struct ProjectRepositoryExtendedTests {

    @Test("findAll returns all saved projects")
    @MainActor
    func testFindAll() async throws {
        let container = try ModelContainer(
            for: ProjectEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let repository = ProjectRepository(modelContext: context)

        let ownerId = UUID()
        for i in 1...2 {
            let project = Project(
                id: UUID(),
                name: "Project \(i)",
                description: "Desc \(i)",
                ownerId: ownerId,
                status: .active,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await repository.save(project)
        }

        let all = try await repository.findAll()
        #expect(all.count == 2)
    }

    @Test("search matches name case-insensitively")
    @MainActor
    func testSearchMatchesName() async throws {
        let container = try ModelContainer(
            for: ProjectEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let repository = ProjectRepository(modelContext: context)

        let project = Project(
            id: UUID(),
            name: "Materials Analysis",
            description: "Unrelated",
            ownerId: UUID(),
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await repository.save(project)

        let results = try await repository.search(query: "materials")
        #expect(results.count == 1)
        #expect(results.first?.name == "Materials Analysis")
    }

    @Test("search matches description")
    @MainActor
    func testSearchMatchesDescription() async throws {
        let container = try ModelContainer(
            for: ProjectEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let repository = ProjectRepository(modelContext: context)

        let project = Project(
            id: UUID(),
            name: "Unrelated Name",
            description: "Contains defect detection keywords",
            ownerId: UUID(),
            status: .draft,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await repository.save(project)

        let results = try await repository.search(query: "defect")
        #expect(results.count == 1)
        #expect(results.first?.name == "Unrelated Name")
    }

    @Test("delete non-existent ID throws RepositoryError")
    @MainActor
    func testDeleteNonExistent() async throws {
        let container = try ModelContainer(
            for: ProjectEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let repository = ProjectRepository(modelContext: context)

        await #expect(throws: RepositoryError.self) {
            try await repository.delete(UUID())
        }
    }
}
