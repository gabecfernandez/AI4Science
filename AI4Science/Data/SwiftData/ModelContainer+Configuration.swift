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
            LabEntity.self,
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
            CaptureMetadataEntity.self,
            AnnotationItem.self,
            AnalysisConfig.self,
            ResultArtifact.self,
            Measurement.self,
            DefectMeasurement.self,
        ])

        let modelConfiguration = ModelConfiguration(
            isStoredInMemoryOnly: false
        )

        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }

    /// Create a preview container for SwiftUI previews
    @MainActor
    static func previewContainer() throws -> ModelContainer {
        let schema = Schema([
            UserEntity.self,
            ProjectEntity.self,
            LabEntity.self,
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
            CaptureMetadataEntity.self,
            AnnotationItem.self,
            AnalysisConfig.self,
            ResultArtifact.self,
            Measurement.self,
            DefectMeasurement.self,
        ])

        let modelConfiguration = ModelConfiguration(
            isStoredInMemoryOnly: true
        )

        let container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )

        // Add sample data
        addSampleDataToPreview(container)

        return container
    }

    /// Add sample data for previews
    @MainActor
    private static func addSampleDataToPreview(_ container: ModelContainer) {
        let context = container.mainContext

        let sampleUser = UserEntity(
            id: "preview-user-1",
            email: "preview@ai4science.com",
            fullName: "Preview User"
        )
        context.insert(sampleUser)

        let sampleProject = ProjectEntity(
            id: "preview-project-1",
            name: "Sample Project",
            projectDescription: "A sample project for preview",
            owner: sampleUser,
            projectType: "microscopy"
        )
        context.insert(sampleProject)

        let sampleSample = SampleEntity(
            id: "preview-sample-1",
            name: "Test Sample",
            sampleDescription: "A test sample",
            project: sampleProject,
            sampleType: "tissue"
        )
        context.insert(sampleSample)

        try? context.save()
    }
}
