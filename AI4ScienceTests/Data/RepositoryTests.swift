//
//  RepositoryTests.swift
//  AI4ScienceTests
//
//  Created for AI4Science UTSA
//

import Testing
import Foundation
import SwiftData
@testable import AI4Science

@Suite("Repository Protocol Tests")
struct RepositoryProtocolTests {

    @Test("Repository protocol defines required methods")
    func testRepositoryProtocol() {
        // Verify the protocol exists and has required associated types
        // This is a compile-time check
        func checkProtocol<R: Repository>(_ repo: R) where R.Entity: Identifiable {
            _ = repo
        }
    }
}

@Suite("User Repository Tests")
struct UserRepositoryTests {

    @Test("User repository saves and retrieves user")
    @MainActor
    func testSaveAndRetrieveUser() async throws {
        let container = try ModelContainer(
            for: UserEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let repository = UserRepository(modelContext: context)

        let user = User(
            id: UUID(),
            email: "test@utsa.edu",
            displayName: "Test User",
            role: .researcher,
            labAffiliation: nil
        )

        try await repository.save(user)

        let retrieved = try await repository.findById(user.id)

        #expect(retrieved != nil)
        #expect(retrieved?.email == user.email)
    }

    @Test("User repository finds by email")
    @MainActor
    func testFindByEmail() async throws {
        let container = try ModelContainer(
            for: UserEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let repository = UserRepository(modelContext: context)

        let user = User(
            id: UUID(),
            email: "unique@utsa.edu",
            displayName: "Unique User",
            role: .citizen,
            labAffiliation: nil
        )

        try await repository.save(user)

        let found = try await repository.findByEmail("unique@utsa.edu")

        #expect(found != nil)
        #expect(found?.id == user.id)
    }

    @Test("User repository deletes user")
    @MainActor
    func testDeleteUser() async throws {
        let container = try ModelContainer(
            for: UserEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let repository = UserRepository(modelContext: context)

        let user = User(
            id: UUID(),
            email: "delete@utsa.edu",
            displayName: "Delete Me",
            role: .citizen,
            labAffiliation: nil
        )

        try await repository.save(user)
        try await repository.delete(user.id)

        let retrieved = try await repository.findById(user.id)
        #expect(retrieved == nil)
    }
}

@Suite("Project Repository Tests")
struct ProjectRepositoryTests {

    @Test("Project repository CRUD operations")
    @MainActor
    func testProjectCRUD() async throws {
        let container = try ModelContainer(
            for: ProjectEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let repository = ProjectRepository(modelContext: context)

        let project = Project(
            id: UUID(),
            name: "Test Project",
            description: "A test project",
            ownerId: UUID(),
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Create
        try await repository.save(project)

        // Read
        let retrieved = try await repository.findById(project.id)
        #expect(retrieved != nil)
        #expect(retrieved?.name == "Test Project")

        // Update
        var updated = project
        updated.name = "Updated Project"
        try await repository.save(updated)

        let afterUpdate = try await repository.findById(project.id)
        #expect(afterUpdate?.name == "Updated Project")

        // Delete
        try await repository.delete(project.id)
        let afterDelete = try await repository.findById(project.id)
        #expect(afterDelete == nil)
    }

    @Test("Project repository finds by owner")
    @MainActor
    func testFindByOwner() async throws {
        let container = try ModelContainer(
            for: ProjectEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let repository = ProjectRepository(modelContext: context)
        let ownerId = UUID()

        for i in 1...3 {
            let project = Project(
                id: UUID(),
                name: "Project \(i)",
                description: "Description \(i)",
                ownerId: ownerId,
                status: .active,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await repository.save(project)
        }

        let ownerProjects = try await repository.findByOwner(ownerId)
        #expect(ownerProjects.count == 3)
    }

    @Test("Project repository finds by status")
    @MainActor
    func testFindByStatus() async throws {
        let container = try ModelContainer(
            for: ProjectEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let repository = ProjectRepository(modelContext: context)

        let activeProject = Project(
            id: UUID(),
            name: "Active",
            description: "Active project",
            ownerId: UUID(),
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )

        let draftProject = Project(
            id: UUID(),
            name: "Draft",
            description: "Draft project",
            ownerId: UUID(),
            status: .draft,
            createdAt: Date(),
            updatedAt: Date()
        )

        try await repository.save(activeProject)
        try await repository.save(draftProject)

        let activeProjects = try await repository.findByStatus(.active)
        #expect(activeProjects.count == 1)
        #expect(activeProjects.first?.name == "Active")
    }
}

@Suite("Capture Repository Tests")
struct CaptureRepositoryTests {

    @Test("Capture repository saves with file reference")
    @MainActor
    func testSaveCaptureWithFile() async throws {
        let container = try ModelContainer(
            for: CaptureEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let repository = CaptureRepository(modelContext: context)

        let capture = Capture(
            id: UUID(),
            sampleId: UUID(),
            type: .photo,
            fileURL: URL(fileURLWithPath: "/test/photo.heic"),
            thumbnailURL: URL(fileURLWithPath: "/test/thumb.jpg"),
            metadata: CaptureMetadata(
                width: 4032,
                height: 3024,
                colorSpace: .sRGB,
                captureDate: Date(),
                deviceModel: "iPhone"
            ),
            createdAt: Date(),
            createdBy: UUID()
        )

        try await repository.save(capture)

        let retrieved = try await repository.findById(capture.id)
        #expect(retrieved != nil)
        #expect(retrieved?.fileURL == capture.fileURL)
    }

    @Test("Capture repository finds by sample")
    @MainActor
    func testFindBySample() async throws {
        let container = try ModelContainer(
            for: CaptureEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let repository = CaptureRepository(modelContext: context)
        let sampleId = UUID()

        for i in 1...5 {
            let capture = Capture(
                id: UUID(),
                sampleId: sampleId,
                type: i % 2 == 0 ? .photo : .video,
                fileURL: URL(fileURLWithPath: "/test/capture_\(i)"),
                thumbnailURL: nil,
                metadata: CaptureMetadata(
                    width: 1920,
                    height: 1080,
                    colorSpace: .sRGB,
                    captureDate: Date(),
                    deviceModel: "iPhone"
                ),
                createdAt: Date(),
                createdBy: UUID()
            )
            try await repository.save(capture)
        }

        let sampleCaptures = try await repository.findBySample(sampleId)
        #expect(sampleCaptures.count == 5)
    }
}
