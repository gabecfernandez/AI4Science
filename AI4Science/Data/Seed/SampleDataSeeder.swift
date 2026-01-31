import Foundation
import SwiftData

/// Seeds the database with sample data for development and demonstration
@MainActor
enum SampleDataSeeder {

    /// Seed sample data if the database is empty
    static func seedIfEmpty(modelContext: ModelContext) async {
        // Check if projects already exist
        var projectDescriptor = FetchDescriptor<ProjectEntity>()
        projectDescriptor.fetchLimit = 1

        do {
            let existingProjects = try modelContext.fetch(projectDescriptor)
            if !existingProjects.isEmpty {
                AppLogger.shared.debug("Database already has data, skipping seed")
                return
            }
        } catch {
            AppLogger.shared.error("Failed to check existing data: \(error)")
            return
        }

        AppLogger.shared.info("Seeding sample data...")

        // Create sample user
        let sampleUser = createSampleUser()
        modelContext.insert(sampleUser)

        // Create sample projects
        let projects = createSampleProjects(owner: sampleUser)
        for project in projects {
            modelContext.insert(project)
        }

        // Create sample samples for first project
        if let firstProject = projects.first {
            let samples = createSampleSamples(project: firstProject)
            for sample in samples {
                modelContext.insert(sample)
            }
        }

        do {
            try modelContext.save()
            AppLogger.shared.info("Sample data seeded successfully: \(projects.count) projects")
        } catch {
            AppLogger.shared.error("Failed to save sample data: \(error)")
        }
    }

    // MARK: - Sample Data Creation

    private static func createSampleUser() -> UserEntity {
        UserEntity(
            id: UUID().uuidString,
            email: "demo@utsa.edu",
            fullName: "Dr. Sarah Chen",
            institution: "UT San Antonio",
            createdAt: Date().addingTimeInterval(-86400 * 365) // 1 year ago
        )
    }

    private static func createSampleProjects(owner: UserEntity) -> [ProjectEntity] {
        let now = Date()

        let project1 = ProjectEntity(
            id: UUID().uuidString,
            name: "Materials Analysis 2024",
            projectDescription: "Comprehensive analysis of novel composite materials for aerospace applications. This project uses AI-powered defect detection to identify structural anomalies in carbon fiber composites.",
            owner: owner,
            createdAt: now.addingTimeInterval(-86400 * 30),
            updatedAt: now.addingTimeInterval(-3600),
            projectType: "materials"
        )
        project1.status = ProjectStatus.active.rawValue
        project1.sampleCount = 47
        project1.tags = ["aerospace", "composites", "defect-detection"]
        project1.startDate = now.addingTimeInterval(-86400 * 30)

        let project2 = ProjectEntity(
            id: UUID().uuidString,
            name: "Protein Structure Study",
            projectDescription: "AI-driven analysis of protein folding patterns using advanced microscopy images. Collaborating with the UTSA Biology department.",
            owner: owner,
            createdAt: now.addingTimeInterval(-86400 * 60),
            updatedAt: now.addingTimeInterval(-86400 * 2),
            projectType: "biology"
        )
        project2.status = ProjectStatus.active.rawValue
        project2.sampleCount = 128
        project2.tags = ["proteins", "microscopy", "AI"]
        project2.startDate = now.addingTimeInterval(-86400 * 60)

        let project3 = ProjectEntity(
            id: UUID().uuidString,
            name: "Crystal Growth Optimization",
            projectDescription: "Testing growth parameters for semiconductor crystals. Currently on hold pending equipment calibration.",
            owner: owner,
            createdAt: now.addingTimeInterval(-86400 * 90),
            updatedAt: now.addingTimeInterval(-86400 * 14),
            projectType: "semiconductor"
        )
        project3.status = ProjectStatus.onHold.rawValue
        project3.sampleCount = 23
        project3.tags = ["crystals", "semiconductor", "growth-optimization"]
        project3.startDate = now.addingTimeInterval(-86400 * 90)

        let project4 = ProjectEntity(
            id: UUID().uuidString,
            name: "Pilot: Surface Texture Analysis",
            projectDescription: "Initial pilot study for automated surface texture classification. Successfully validated the ML pipeline.",
            owner: owner,
            createdAt: now.addingTimeInterval(-86400 * 180),
            updatedAt: now.addingTimeInterval(-86400 * 45),
            projectType: "materials"
        )
        project4.status = ProjectStatus.completed.rawValue
        project4.sampleCount = 15
        project4.tags = ["pilot", "texture", "validation"]
        project4.startDate = now.addingTimeInterval(-86400 * 180)

        let project5 = ProjectEntity(
            id: UUID().uuidString,
            name: "Nanomaterial Characterization",
            projectDescription: "Upcoming project to characterize nanomaterial properties using electron microscopy and AI analysis.",
            owner: owner,
            createdAt: now.addingTimeInterval(-86400 * 7),
            updatedAt: now.addingTimeInterval(-86400),
            projectType: "nanomaterials"
        )
        project5.status = ProjectStatus.planning.rawValue
        project5.sampleCount = 0
        project5.tags = ["nanomaterials", "electron-microscopy", "planning"]
        project5.startDate = nil

        return [project1, project2, project3, project4, project5]
    }

    private static func createSampleSamples(project: ProjectEntity) -> [SampleEntity] {
        let now = Date()

        return [
            SampleEntity(
                id: UUID().uuidString,
                name: "CF-001-A",
                sampleDescription: "Carbon fiber sample from batch A - standard weave pattern",
                project: project,
                sampleType: "composite",
                createdAt: now.addingTimeInterval(-86400 * 28)
            ),
            SampleEntity(
                id: UUID().uuidString,
                name: "CF-001-B",
                sampleDescription: "Carbon fiber sample from batch A - reinforced weave pattern",
                project: project,
                sampleType: "composite",
                createdAt: now.addingTimeInterval(-86400 * 27)
            ),
            SampleEntity(
                id: UUID().uuidString,
                name: "CF-002-A",
                sampleDescription: "Carbon fiber sample from batch B - with epoxy matrix",
                project: project,
                sampleType: "composite",
                createdAt: now.addingTimeInterval(-86400 * 25)
            )
        ]
    }
}
