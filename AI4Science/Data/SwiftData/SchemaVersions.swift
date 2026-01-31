import Foundation
import SwiftData

/// Version 1 of the schema (initial release)
@available(iOS 18, *)
enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
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
            CaptureMetadataEntity.self,
            AnnotationItem.self,
            AnalysisConfig.self,
            ResultArtifact.self,
            DefectMeasurement.self,
        ]
    }
}

/// Migration plan for database schema evolution
@available(iOS 18, *)
enum AI4ScienceSchemaMigrationPlan: SwiftData.SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // Migration stages to be added as schema evolves
        []
    }
}

/// Helper for managing schema changes
struct SchemaChanges {
    /// Document schema version for tracking
    static let currentVersion = "1.0.0"

    /// Check if migration is needed
    static func requiresMigration(from version: String) -> Bool {
        // Compare versions
        return version != currentVersion
    }

    /// Get migration steps for version
    static func migrationSteps(from oldVersion: String) -> [String] {
        // Define migration steps based on version
        return []
    }
}
