//
//  ProjectTests.swift
//  AI4ScienceTests
//
//  Created for AI4Science UTSA
//

import Testing
import Foundation
@testable import AI4Science

@Suite("Project Model Tests")
struct ProjectTests {

    // MARK: - Initialization Tests

    @Test("Project initializes with required properties")
    func testProjectInitialization() {
        let ownerId = UUID()
        let project = Project(
            id: UUID(),
            name: "Materials Analysis Study",
            description: "Analyzing material defects using ML",
            ownerId: ownerId,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(project.name == "Materials Analysis Study")
        #expect(project.ownerId == ownerId)
        #expect(project.status == .active)
    }

    @Test("Project status transitions")
    func testProjectStatusTransitions() {
        var project = Project(
            id: UUID(),
            name: "Test Project",
            description: "Test",
            ownerId: UUID(),
            status: .draft,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Draft -> Active
        #expect(project.canTransitionTo(.active))
        project.status = .active

        // Active -> Paused
        #expect(project.canTransitionTo(.paused))
        project.status = .paused

        // Paused -> Active
        #expect(project.canTransitionTo(.active))
        project.status = .active

        // Active -> Completed
        #expect(project.canTransitionTo(.completed))
        project.status = .completed

        // Completed cannot go back to active
        #expect(!project.canTransitionTo(.active))
    }

    // MARK: - Sample Management Tests

    @Test("Project tracks sample count")
    func testProjectSampleCount() {
        var project = Project(
            id: UUID(),
            name: "Sample Project",
            description: "Testing samples",
            ownerId: UUID(),
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(project.sampleIds.isEmpty)

        let sampleId = UUID()
        project.sampleIds.append(sampleId)

        #expect(project.sampleIds.count == 1)
        #expect(project.sampleIds.contains(sampleId))
    }

    // MARK: - Collaborator Tests

    @Test("Project manages collaborators")
    func testProjectCollaborators() {
        var project = Project(
            id: UUID(),
            name: "Collaborative Project",
            description: "Testing collaboration",
            ownerId: UUID(),
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )

        let collaboratorId = UUID()
        project.collaboratorIds.append(collaboratorId)

        #expect(project.collaboratorIds.contains(collaboratorId))
        #expect(project.isCollaborator(userId: collaboratorId))
    }

    // MARK: - Codable Tests

    @Test("Project encodes and decodes correctly")
    func testProjectCodable() throws {
        let project = Project(
            id: UUID(),
            name: "Codable Test",
            description: "Testing serialization",
            ownerId: UUID(),
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(project)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Project.self, from: data)

        #expect(decoded.id == project.id)
        #expect(decoded.name == project.name)
        #expect(decoded.status == project.status)
    }

    // MARK: - Date Tests

    @Test("Project tracks creation and update dates")
    func testProjectDates() {
        let createdAt = Date()
        var project = Project(
            id: UUID(),
            name: "Date Test",
            description: "Testing dates",
            ownerId: UUID(),
            status: .draft,
            createdAt: createdAt,
            updatedAt: createdAt
        )

        #expect(project.createdAt == createdAt)

        // Simulate update
        let newDate = Date()
        project.updatedAt = newDate

        #expect(project.updatedAt >= project.createdAt)
    }
}

// MARK: - Project Status Tests

@Suite("Project Status Tests")
struct ProjectStatusTests {

    @Test("All project statuses are represented")
    func testAllStatuses() {
        let statuses: [ProjectStatus] = [.draft, .active, .paused, .completed, .archived]
        #expect(statuses.count == 5)
    }

    @Test("Status display names are correct")
    func testStatusDisplayNames() {
        #expect(ProjectStatus.draft.displayName == "Draft")
        #expect(ProjectStatus.active.displayName == "Active")
        #expect(ProjectStatus.paused.displayName == "Paused")
        #expect(ProjectStatus.completed.displayName == "Completed")
        #expect(ProjectStatus.archived.displayName == "Archived")
    }

    @Test("Status colors are defined")
    func testStatusColors() {
        for status in ProjectStatus.allCases {
            #expect(status.color != nil)
        }
    }
}
