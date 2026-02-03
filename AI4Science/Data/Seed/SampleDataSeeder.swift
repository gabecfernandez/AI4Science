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

        // Create sample labs and wire M2M membership
        let labs = createSampleLabs(owner: sampleUser)
        for lab in labs {
            modelContext.insert(lab)
        }
        // Create additional lab members for richer demo data
        let extraMembers = createExtraMembers()
        for member in extraMembers { modelContext.insert(member) }

        // Wire members to labs (lab-side; auto-populates user.labs bidirectionally)
        labs[0].members = [sampleUser, extraMembers[0], extraMembers[1], extraMembers[2]]
        labs[1].members = [sampleUser, extraMembers[1], extraMembers[3]]
        // labs[2] has no members (Explore-only, joinable via UI)

        // Create sample projects
        let projects = createSampleProjects(owner: sampleUser)
        for project in projects {
            modelContext.insert(project)
        }

        // Wire projects to labs (M2M — some projects span multiple labs)
        projects[0].labs = [labs[0], labs[1]]   // Materials Analysis 2024        → Vision & AI + Advanced Materials
        projects[1].labs = [labs[0], labs[2]]   // Protein Structure Study        → Vision & AI + Bio-Imaging
        projects[2].labs = [labs[1]]            // Crystal Growth Optimization    → Advanced Materials
        projects[3].labs = [labs[1]]            // Pilot: Surface Texture Analysis → Advanced Materials
        // projects[4] stays unassigned (planning stage)

        // Completed projects for Vision & AI Lab (show in Past Projects)
        let completedProjects = createCompletedProjects(owner: sampleUser)
        for cp in completedProjects {
            modelContext.insert(cp)
            cp.labs = [labs[0]]
        }

        // Create sample samples for first project
        var samples: [SampleEntity] = []
        if let firstProject = projects.first {
            samples = createSampleSamples(project: firstProject)
            for sample in samples {
                modelContext.insert(sample)
            }
        }

        // Create sample captures for first two samples
        var captures: [CaptureEntity] = []
        if samples.count >= 2 {
            captures = createSampleCaptures(samples: Array(samples.prefix(2)))
            for capture in captures {
                modelContext.insert(capture)
            }
        }

        // Create sample ML models
        let mlModels = createSampleMLModels()
        for model in mlModels {
            modelContext.insert(model)
        }

        // Create sample analysis results for captures
        if !captures.isEmpty, let defectModel = mlModels.first {
            let analysisResults = createSampleAnalysisResults(
                captures: captures,
                model: defectModel
            )
            for result in analysisResults {
                modelContext.insert(result)
            }
        }

        do {
            try modelContext.save()
            AppLogger.shared.info("Sample data seeded successfully: \(projects.count) projects, \(captures.count) captures")
        } catch {
            AppLogger.shared.error("Failed to save sample data: \(error)")
        }
    }

    /// Seeds labs into an existing database that was seeded before labs existed.
    /// No-op if labs are already present.
    static func seedLabsIfNeeded(modelContext: ModelContext) async {
        var labDescriptor = FetchDescriptor<LabEntity>()
        labDescriptor.fetchLimit = 1

        do {
            let existingLabs = try modelContext.fetch(labDescriptor)
            if !existingLabs.isEmpty { return }
        } catch {
            AppLogger.shared.error("Failed to check existing labs: \(error)")
            return
        }

        // Fetch the existing seeded user
        let userDescriptor = FetchDescriptor<UserEntity>()
        guard let sampleUser = try? modelContext.fetch(userDescriptor).first else {
            AppLogger.shared.warning("No user found — cannot seed labs")
            return
        }

        AppLogger.shared.info("Seeding labs into existing database...")

        let labs = createSampleLabs(owner: sampleUser)
        for lab in labs { modelContext.insert(lab) }
        sampleUser.labs = [labs[0], labs[1]]

        // Wire existing projects to labs by name (M2M)
        let projectDescriptor = FetchDescriptor<ProjectEntity>()
        if let projects = try? modelContext.fetch(projectDescriptor) {
            for project in projects {
                switch project.name {
                case "Materials Analysis 2024":
                    project.labs = [labs[0], labs[1]]
                case "Protein Structure Study":
                    project.labs = [labs[0], labs[2]]
                case "Crystal Growth Optimization", "Pilot: Surface Texture Analysis":
                    project.labs = [labs[1]]
                default:
                    break
                }
            }
        }

        do {
            try modelContext.save()
            AppLogger.shared.info("Labs seeded successfully")
        } catch {
            AppLogger.shared.error("Failed to save lab seed data: \(error)")
        }
    }

    /// Seeds additional lab members and completed projects for richer demo data.
    /// Idempotent — uses sentinel checks (known email / project name) rather than
    /// user count, which can be thrown off by a real Supabase sign-in.
    static func seedExtraLabMembersIfNeeded(modelContext: ModelContext) async {
        // Need labs to exist so we can wire memberships
        let labDescriptor = FetchDescriptor<LabEntity>()
        guard let labs        = try? modelContext.fetch(labDescriptor),
              let visionAI    = labs.first(where: { $0.id == "lab-vision-ai-utsa" }),
              let materials   = labs.first(where: { $0.id == "lab-materials-utsa" }) else { return }

        // Find the original demo user (owner of the labs)
        guard let sampleUser = visionAI.owner else { return }

        // --- Members: gate on sentinel email ----------------------------------------
        let memberSentinel = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.email == "mjones@utsa.edu" }
        )
        if let existing = try? modelContext.fetch(memberSentinel), existing.isEmpty {
            AppLogger.shared.info("Seeding extra lab members...")
            let extraMembers = createExtraMembers()
            for member in extraMembers { modelContext.insert(member) }

            visionAI.members.append(contentsOf: [extraMembers[0], extraMembers[1], extraMembers[2]])
            materials.members.append(contentsOf: [extraMembers[1], extraMembers[3]])
        }

        // --- Completed projects: gate on sentinel project name -----------------------
        let projSentinel = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { $0.name == "Defect Detection Benchmark" }
        )
        if let existing = try? modelContext.fetch(projSentinel), existing.isEmpty {
            AppLogger.shared.info("Seeding completed projects...")
            let completedProjects = createCompletedProjects(owner: sampleUser)
            for project in completedProjects {
                modelContext.insert(project)
                project.labs = [visionAI]
            }
        }

        do {
            try modelContext.save()
            AppLogger.shared.info("Extra lab seed data applied successfully")
        } catch {
            AppLogger.shared.error("Failed to save extra lab seed data: \(error)")
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

    private static func createSampleLabs(owner: UserEntity) -> [LabEntity] {
        let now = Date()

        let visionAILab = LabEntity(
            id: "lab-vision-ai-utsa",
            name: "Vision & AI Lab",
            abbreviation: "VAI",
            labDescription: "Research lab focused on computer vision and artificial intelligence applications in materials science. Develops on-device ML models for real-time defect detection and material classification.",
            institution: "UT San Antonio",
            isPublic: true,
            createdAt: now.addingTimeInterval(-86400 * 365),
            updatedAt: now.addingTimeInterval(-86400 * 7)
        )
        visionAILab.owner = owner

        let materialsLab = LabEntity(
            id: "lab-materials-utsa",
            name: "Advanced Materials Lab",
            abbreviation: "AML",
            labDescription: "Specializes in characterization and testing of advanced composite materials including carbon fiber, ceramics, and nanomaterials. Equipped with electron microscopy and surface analysis tools.",
            institution: "UT San Antonio",
            isPublic: true,
            createdAt: now.addingTimeInterval(-86400 * 300),
            updatedAt: now.addingTimeInterval(-86400 * 14)
        )
        materialsLab.owner = owner

        let bioImagingLab = LabEntity(
            id: "lab-bio-imaging-utsa",
            name: "Bio-Imaging Research Lab",
            abbreviation: "BIR",
            labDescription: "Focuses on high-resolution bio-imaging techniques for studying cellular structures and biological materials. Collaborates with the UTSA Biology and Medical Sciences departments.",
            institution: "UT San Antonio",
            isPublic: true,
            createdAt: now.addingTimeInterval(-86400 * 200),
            updatedAt: now.addingTimeInterval(-86400 * 30)
        )

        return [visionAILab, materialsLab, bioImagingLab]
    }

    /// Four additional researchers / students used as lab members in the demo.
    private static func createExtraMembers() -> [UserEntity] {
        let now = Date()
        return [
            UserEntity(
                id: UUID().uuidString,
                email: "mjones@utsa.edu",
                fullName: "Dr. Marcus Jones",
                institution: "UT San Antonio",
                createdAt: now.addingTimeInterval(-86400 * 500)
            ),
            UserEntity(
                id: UUID().uuidString,
                email: "rlim@utsa.edu",
                fullName: "Rachel Lim",
                institution: "UT San Antonio",
                createdAt: now.addingTimeInterval(-86400 * 400)
            ),
            UserEntity(
                id: UUID().uuidString,
                email: "kpatel@utsa.edu",
                fullName: "Kai Patel",
                institution: "UT San Antonio",
                createdAt: now.addingTimeInterval(-86400 * 300)
            ),
            UserEntity(
                id: UUID().uuidString,
                email: "awilson@utsa.edu",
                fullName: "Prof. Amy Wilson",
                institution: "UT San Antonio",
                createdAt: now.addingTimeInterval(-86400 * 600)
            )
        ]
    }

    /// Completed projects that populate the "Past Projects" section of Vision & AI Lab.
    private static func createCompletedProjects(owner: UserEntity) -> [ProjectEntity] {
        let now = Date()

        let benchmark = ProjectEntity(
            id: UUID().uuidString,
            name: "Defect Detection Benchmark",
            projectDescription: "Benchmarking defect detection models against a curated dataset of known defects in carbon fiber composites. Completed with 94% accuracy on the held-out test set.",
            owner: owner,
            createdAt: now.addingTimeInterval(-86400 * 240),
            updatedAt: now.addingTimeInterval(-86400 * 60),
            projectType: "materials"
        )
        benchmark.status = ProjectStatus.completed.rawValue
        benchmark.sampleCount = 200
        benchmark.tags = ["benchmark", "defect-detection", "validation"]
        benchmark.startDate = now.addingTimeInterval(-86400 * 240)

        let classification = ProjectEntity(
            id: UUID().uuidString,
            name: "Surface Defect Classification",
            projectDescription: "Trained and validated a multi-class CNN for classifying surface defects in steel sheets. Achieved 97% top-1 accuracy across crack, scratch, and inclusion classes.",
            owner: owner,
            createdAt: now.addingTimeInterval(-86400 * 400),
            updatedAt: now.addingTimeInterval(-86400 * 120),
            projectType: "materials"
        )
        classification.status = ProjectStatus.completed.rawValue
        classification.sampleCount = 350
        classification.tags = ["classification", "CNN", "steel", "completed"]
        classification.startDate = now.addingTimeInterval(-86400 * 400)

        return [benchmark, classification]
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

    // MARK: - Sample Captures

    private static func createSampleCaptures(samples: [SampleEntity]) -> [CaptureEntity] {
        let now = Date()
        var captures: [CaptureEntity] = []

        // Captures for first sample (CF-001-A)
        if let sample1 = samples.first {
            let capture1 = CaptureEntity(
                id: UUID().uuidString,
                sample: sample1,
                captureType: "microscopy",
                fileURL: "file:///captures/placeholder_microscopy_001.jpg",
                mimeType: "image/jpeg",
                capturedAt: now.addingTimeInterval(-86400 * 20)
            )
            capture1.fileSize = 4_500_000
            capture1.processingStatus = "completed"
            capture1.qualityScore = 0.95
            capture1.isProcessed = true
            capture1.notes = "4K microscopy capture at 100x magnification"
            capture1.deviceInfo = "Zeiss Axio Observer"
            capture1.cameraSettings = [
                "magnification": "100x",
                "exposure": "1/500",
                "resolution": "3840x2160"
            ]
            captures.append(capture1)

            let capture2 = CaptureEntity(
                id: UUID().uuidString,
                sample: sample1,
                captureType: "photo",
                fileURL: "file:///captures/placeholder_photo_001.jpg",
                mimeType: "image/jpeg",
                capturedAt: now.addingTimeInterval(-86400 * 18)
            )
            capture2.fileSize = 2_100_000
            capture2.processingStatus = "completed"
            capture2.qualityScore = 0.87
            capture2.isProcessed = true
            capture2.notes = "Standard documentation photo"
            capture2.deviceInfo = "iPhone 15 Pro"
            captures.append(capture2)

            let capture3 = CaptureEntity(
                id: UUID().uuidString,
                sample: sample1,
                captureType: "scan",
                fileURL: "file:///captures/placeholder_scan_001.tiff",
                mimeType: "image/tiff",
                capturedAt: now.addingTimeInterval(-86400 * 2)
            )
            capture3.fileSize = 15_000_000
            capture3.processingStatus = "processing"
            capture3.qualityScore = 0.92
            capture3.isProcessed = false
            capture3.notes = "High-resolution surface scan"
            capture3.deviceInfo = "Keyence VK-X3000"
            captures.append(capture3)
        }

        // Captures for second sample (CF-001-B)
        if samples.count > 1 {
            let sample2 = samples[1]

            let capture4 = CaptureEntity(
                id: UUID().uuidString,
                sample: sample2,
                captureType: "microscopy",
                fileURL: "file:///captures/placeholder_microscopy_002.jpg",
                mimeType: "image/jpeg",
                capturedAt: now.addingTimeInterval(-86400 * 15)
            )
            capture4.fileSize = 4_200_000
            capture4.processingStatus = "completed"
            capture4.qualityScore = 0.89
            capture4.isProcessed = true
            capture4.notes = "Reinforced weave pattern analysis"
            capture4.deviceInfo = "Zeiss Axio Observer"
            capture4.cameraSettings = [
                "magnification": "50x",
                "exposure": "1/250",
                "resolution": "3840x2160"
            ]
            captures.append(capture4)

            let capture5 = CaptureEntity(
                id: UUID().uuidString,
                sample: sample2,
                captureType: "video",
                fileURL: "file:///captures/placeholder_video_001.mov",
                mimeType: "video/quicktime",
                capturedAt: now.addingTimeInterval(-86400 * 10)
            )
            capture5.fileSize = 125_000_000
            capture5.processingStatus = "pending"
            capture5.qualityScore = 0.78
            capture5.isProcessed = false
            capture5.notes = "Time-lapse stress test recording"
            capture5.deviceInfo = "iPhone 15 Pro"
            captures.append(capture5)
        }

        return captures
    }

    // MARK: - Sample ML Models

    private static func createSampleMLModels() -> [MLModelEntity] {
        let now = Date()

        let defectModel = MLModelEntity(
            id: UUID().uuidString,
            name: "DefectDetectionV2",
            modelDescription: "Advanced defect detection model for composite materials. Identifies cracks, delaminations, and voids.",
            version: "2.1.0",
            modelType: "detection",
            framework: "CoreML",
            inputSpec: "{\"type\": \"image\", \"format\": \"RGB\", \"size\": [640, 640]}",
            outputSpec: "{\"type\": \"bounding_boxes\", \"classes\": [\"crack\", \"void\", \"delamination\", \"inclusion\"]}"
        )
        defectModel.downloadStatus = "downloaded"
        defectModel.downloadProgress = 1.0
        defectModel.localPath = "/models/defect_detection_v2.mlmodelc"
        defectModel.fileSize = 45_000_000
        defectModel.performanceMetrics = ["accuracy": 0.94, "f1_score": 0.91, "inference_ms": 45]
        defectModel.supportedFormats = ["JPEG", "PNG", "TIFF"]
        defectModel.createdAt = now.addingTimeInterval(-86400 * 90)
        defectModel.updatedAt = now.addingTimeInterval(-86400 * 30)

        let classifierModel = MLModelEntity(
            id: UUID().uuidString,
            name: "MaterialClassifier",
            modelDescription: "Classifies material types from microscopy images. Supports carbon fiber, fiberglass, and Kevlar composites.",
            version: "1.3.0",
            modelType: "classification",
            framework: "CoreML",
            inputSpec: "{\"type\": \"image\", \"format\": \"RGB\", \"size\": [224, 224]}",
            outputSpec: "{\"type\": \"classification\", \"classes\": [\"carbon_fiber\", \"fiberglass\", \"kevlar\", \"hybrid\"]}"
        )
        classifierModel.downloadStatus = "downloaded"
        classifierModel.downloadProgress = 1.0
        classifierModel.localPath = "/models/material_classifier_v1.mlmodelc"
        classifierModel.fileSize = 28_000_000
        classifierModel.performanceMetrics = ["accuracy": 0.91, "top3_accuracy": 0.98, "inference_ms": 25]
        classifierModel.supportedFormats = ["JPEG", "PNG"]
        classifierModel.createdAt = now.addingTimeInterval(-86400 * 120)
        classifierModel.updatedAt = now.addingTimeInterval(-86400 * 60)

        return [defectModel, classifierModel]
    }

    // MARK: - Sample Analysis Results

    private static func createSampleAnalysisResults(
        captures: [CaptureEntity],
        model: MLModelEntity
    ) -> [AnalysisResultEntity] {
        let now = Date()
        var results: [AnalysisResultEntity] = []

        // Result for first capture (microscopy - completed with findings)
        if let capture1 = captures.first {
            let result1 = AnalysisResultEntity(
                id: UUID().uuidString,
                capture: capture1,
                modelID: model.id,
                modelName: model.name,
                modelVersion: model.version,
                analysisType: "defect_detection",
                resultData: "{\"detections\": [{\"class\": \"void\", \"confidence\": 0.94, \"bbox\": [120, 340, 45, 38]}, {\"class\": \"crack\", \"confidence\": 0.88, \"bbox\": [560, 180, 12, 95]}, {\"class\": \"inclusion\", \"confidence\": 0.76, \"bbox\": [890, 520, 22, 18]}]}",
                startedAt: now.addingTimeInterval(-86400 * 19)
            )
            result1.status = "completed"
            result1.completedAt = now.addingTimeInterval(-86400 * 19 + 120)
            result1.duration = 120
            result1.confidenceScore = 0.92
            result1.objectCount = 3
            result1.isReviewed = true
            result1.reviewNotes = "Confirmed 2 of 3 detections. Inclusion detection may be false positive."
            result1.parameters = ["confidence_threshold": "0.7", "nms_threshold": "0.5"]
            results.append(result1)
        }

        // Result for second capture (photo - completed)
        if captures.count > 1 {
            let result2 = AnalysisResultEntity(
                id: UUID().uuidString,
                capture: captures[1],
                modelID: model.id,
                modelName: "MaterialClassifier",
                modelVersion: "1.3.0",
                analysisType: "classification",
                resultData: "{\"classification\": \"carbon_fiber\", \"confidence\": 0.96, \"alternatives\": [{\"class\": \"hybrid\", \"confidence\": 0.03}]}",
                startedAt: now.addingTimeInterval(-86400 * 17)
            )
            result2.status = "completed"
            result2.completedAt = now.addingTimeInterval(-86400 * 17 + 25)
            result2.duration = 25
            result2.confidenceScore = 0.88
            result2.objectCount = 0
            result2.isReviewed = false
            results.append(result2)
        }

        // Result for third capture (scan - still processing)
        if captures.count > 2 {
            let result3 = AnalysisResultEntity(
                id: UUID().uuidString,
                capture: captures[2],
                modelID: model.id,
                modelName: model.name,
                modelVersion: model.version,
                analysisType: "defect_detection",
                resultData: "{}",
                startedAt: now.addingTimeInterval(-3600)
            )
            result3.status = "processing"
            result3.parameters = ["confidence_threshold": "0.8", "high_resolution": "true"]
            results.append(result3)
        }

        // Result for fourth capture (microscopy - completed with more findings)
        if captures.count > 3 {
            let result4 = AnalysisResultEntity(
                id: UUID().uuidString,
                capture: captures[3],
                modelID: model.id,
                modelName: model.name,
                modelVersion: model.version,
                analysisType: "defect_detection",
                resultData: "{\"detections\": [{\"class\": \"crack\", \"confidence\": 0.97}, {\"class\": \"crack\", \"confidence\": 0.92}, {\"class\": \"void\", \"confidence\": 0.89}, {\"class\": \"delamination\", \"confidence\": 0.85}, {\"class\": \"void\", \"confidence\": 0.79}]}",
                startedAt: now.addingTimeInterval(-86400 * 14)
            )
            result4.status = "completed"
            result4.completedAt = now.addingTimeInterval(-86400 * 14 + 95)
            result4.duration = 95
            result4.confidenceScore = 0.95
            result4.objectCount = 5
            result4.isReviewed = true
            result4.reviewNotes = "All detections confirmed. Sample shows significant wear."
            results.append(result4)
        }

        return results
    }
}
