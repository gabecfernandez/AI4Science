import Foundation
import SwiftData

/// Extension to configure SwiftData ModelContainer for AI4Science app
extension ModelContainer {
    /// Create a properly configured ModelContainer for AI4Science
    /// Includes all models and migration strategy
    static func makeAI4ScienceContainer() throws -> ModelContainer {
        let schema = Schema([
            UserEntity.self,
            ProjectEntity.self,
            SampleEntity.self,
            CaptureEntity.self,
            AnnotationEntity.self,
            MLModelEntity.self,
            AnalysisResultEntity.self,
            SyncQueueEntity.self,
            DefectEntity.self,
            SyncMetadataEntity.self,
            // Supporting models
            DeviceInfo.self,
            ProjectMetadata.self,
            SampleProperties.self,
            CaptureMetadata.self,
            AnnotationItem.self,
            AnalysisConfig.self,
            ResultArtifact.self,
            Measurement.self,
            DefectMeasurement.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowDestructiveMigrationForTypes: [],
            migrationPlan: SchemaMigrationPlan.self
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: SchemaMigrationPlan.self,
            configurations: [modelConfiguration]
        )
    }

    /// Create a preview container for SwiftUI previews
    static func previewContainer() throws -> ModelContainer {
        let schema = Schema([
            UserEntity.self,
            ProjectEntity.self,
            SampleEntity.self,
            CaptureEntity.self,
            AnnotationEntity.self,
            MLModelEntity.self,
            AnalysisResultEntity.self,
            SyncQueueEntity.self,
            DefectEntity.self,
            SyncMetadataEntity.self,
            DeviceInfo.self,
            ProjectMetadata.self,
            SampleProperties.self,
            CaptureMetadata.self,
            AnnotationItem.self,
            AnalysisConfig.self,
            ResultArtifact.self,
            Measurement.self,
            DefectMeasurement.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowDestructiveMigrationForTypes: Schema([
                UserEntity.self,
                ProjectEntity.self,
                SampleEntity.self,
                CaptureEntity.self,
                AnnotationEntity.self,
                MLModelEntity.self,
                AnalysisResultEntity.self,
                SyncQueueEntity.self,
            ])
        )

        let container = try ModelContainer(
            for: schema,
            migrationPlan: SchemaMigrationPlan.self,
            configurations: [modelConfiguration]
        )

        // Add sample data
        await addSampleDataToPreview(container)

        return container
    }

    /// Add sample data for previews
    @MainActor
    private static func addSampleDataToPreview(_ container: ModelContainer) async {
        let context = ModelContext(container)

        let sampleUser = UserEntity(
            id: "preview-user-1",
            email: "preview@ai4science.com",
            fullName: "Preview User"
        )
        context.insert(sampleUser)

        let sampleProject = ProjectEntity(
            id: "preview-project-1",
            name: "Sample Project",
            description: "A sample project for preview",
            owner: sampleUser,
            projectType: "microscopy"
        )
        context.insert(sampleProject)

        let sampleSample = SampleEntity(
            id: "preview-sample-1",
            name: "Test Sample",
            description: "A test sample",
            project: sampleProject,
            sampleType: "tissue"
        )
        context.insert(sampleSample)

        try? context.save()
    }
}

/// Schema versions for tracking migrations
enum SchemaVersions {
    static let v1 = VersionedSchema(version: "v1")
}

/// Migration plan for SwiftData
enum SchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema] {
        [SchemaVersions.v1]
    }

    static var stages: [MigrationStage] {
        // Define migration stages here as schema evolves
        []
    }
}
