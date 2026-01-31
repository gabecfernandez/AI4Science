# AI4Science Data Layer - Quick Start Guide

## Setup

### 1. Initialize ModelContainer
```swift
@main
struct AI4ScienceApp: App {
    let modelContainer: ModelContainer

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }

    init() {
        do {
            modelContainer = try ModelContainer.makeAI4ScienceContainer()
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
}
```

### 2. Setup Data Sources
```swift
class DataManager {
    let modelContainer: ModelContainer
    let fileDataSource: FileDataSource
    let userDefaultsDataSource: UserDefaultsDataSource
    let keychainDataSource: KeychainDataSource
    let apiClient: APIClient

    init(modelContainer: ModelContainer) async throws {
        self.modelContainer = modelContainer
        self.fileDataSource = try await FileDataSource()
        self.userDefaultsDataSource = UserDefaultsDataSource()
        self.keychainDataSource = KeychainDataSource()
        self.apiClient = APIClient(baseURL: URL(string: "https://api.ai4science.com")!)
    }
}
```

## Common Operations

### Create a Project
```swift
let project = ProjectEntity(
    id: UUID().uuidString,
    name: "My Research",
    description: "A new research project",
    owner: currentUser,
    projectType: "microscopy"
)

let context = ModelContext(modelContainer)
context.insert(project)
try context.save()
```

### Create a Sample
```swift
let sample = SampleEntity(
    id: UUID().uuidString,
    name: "Sample A",
    description: "First sample",
    project: project,
    sampleType: "tissue"
)

context.insert(sample)
try context.save()
```

### Capture an Image
```swift
// Save image file
let imageData = capturedImage.pngData()!
let fileURL = try await fileDataSource.saveFile(
    imageData,
    filename: "capture_\(Date().timeIntervalSince1970).png",
    subdirectory: "captures/\(sample.id)"
)

// Create capture entity
let capture = CaptureEntity(
    id: UUID().uuidString,
    sample: sample,
    captureType: "image",
    fileURL: fileURL.path,
    mimeType: "image/png"
)

context.insert(capture)
try context.save()
```

### Add Annotation
```swift
let annotation = AnnotationEntity(
    id: UUID().uuidString,
    capture: capture,
    annotationType: "rectangle",
    content: "Defect area",
    coordinates: "{\"x\": 100, \"y\": 100, \"width\": 50, \"height\": 50}",
    createdBy: currentUser.id,
    label: "Defect"
)

context.insert(annotation)
try context.save()
```

### Store Sensitive Data
```swift
// Store auth token
try await keychainDataSource.storeAuthToken(token)

// Retrieve auth token
let token = await keychainDataSource.retrieveAuthToken()

// Store user preferences
try userDefaultsDataSource.set(userID, forKey: UserDefaultsDataSource.PreferenceKey.userId)
```

### Offline Operations
```swift
// Queue an operation for offline sync
try await syncQueue.enqueue(
    operationType: "create",
    entityType: "annotation",
    entityID: annotation.id,
    data: annotationJSON
)

// Process queue when online
let itemsSynced = await syncQueue.processQueue()
```

### Sync Status
```swift
let status = await syncCoordinator.getSyncStatus()
print("Syncing: \(status.isSyncing)")
print("Pending items: \(status.pendingItemsCount)")
print("Last sync: \(status.statusText)")
```

### Resolve Sync Conflicts
```swift
let resolution = await conflictResolver.resolveConflict(
    entityType: "project",
    entityID: projectID,
    strategy: "merge"
)
```

## Data Flow Architecture

### Read Flow
```
ViewController/ViewModel
    ↓
Repository
    ↓
SwiftDataSource<Entity>
    ↓
ModelContext
    ↓
SwiftData Storage
```

### Write Flow
```
ViewController/ViewModel
    ↓
Repository
    ↓
SwiftDataSource<Entity>
    ↓
ModelContext
    ↓
SwiftData Storage + Sync Queue
    ↓
SyncCoordinator (when online)
    ↓
APIClient
```

### Offline Flow
```
Operation (offline)
    ↓
SyncQueue.enqueue()
    ↓
SyncQueueEntity stored
    ↓
Network becomes available
    ↓
SyncCoordinator processes queue
    ↓
Conflict detection
    ↓
Conflict resolver (if needed)
    ↓
SyncMetadata updated
```

## Repository Usage in ViewModels

```swift
@Observable
class ProjectsViewModel {
    let projectRepository: DefaultRepository<ProjectEntity>
    var projects: [ProjectEntity] = []

    @MainActor
    func loadProjects() async {
        do {
            projects = try await projectRepository.list()
        } catch {
            print("Error loading projects: \(error)")
        }
    }

    @MainActor
    func createProject(name: String) async {
        let project = ProjectEntity(
            id: UUID().uuidString,
            name: name,
            description: "",
            projectType: "microscopy"
        )

        do {
            try await projectRepository.create(project)
            await loadProjects()
        } catch {
            print("Error creating project: \(error)")
        }
    }

    @MainActor
    func deleteProject(_ project: ProjectEntity) async {
        do {
            try await projectRepository.delete(id: project.id)
            await loadProjects()
        } catch {
            print("Error deleting project: \(error)")
        }
    }
}
```

## Network Integration

```swift
actor NetworkDataManager {
    let apiClient: AuthenticatedAPIClient

    func fetchProjectsFromServer() async throws -> [ProjectDTO] {
        return try await apiClient.get(
            endpoint: "/projects",
            as: [ProjectDTO].self
        )
    }

    func uploadCapture(_ capture: CaptureEntity) async throws {
        let data = try FileManager.default.contentsOfFile(atPath: capture.fileURL)
        _ = try await apiClient.post(
            endpoint: "/captures",
            body: CaptureDTO(entity: capture),
            as: CaptureDTO.self
        )
    }
}
```

## Error Handling

```swift
do {
    try await projectRepository.create(project)
} catch APIError.unauthorized {
    // Handle auth failure - refresh token
} catch APIError.serverError(let code) {
    print("Server error: \(code)")
} catch APIError.networkError(let error) {
    // Handle offline - queue operation
    try await syncQueue.enqueue(...)
} catch {
    print("Unknown error: \(error)")
}
```

## Logging

```swift
Logger.info("Starting project creation")
Logger.debug("Project ID: \(project.id)")
Logger.warning("High memory usage detected")
Logger.error("Failed to save project: \(error)")
```

## Testing

### Preview with Sample Data
```swift
#Preview {
    let container = try! ModelContainer.previewContainer()
    return ProjectListView()
        .modelContainer(container)
}
```

### Mock Repository
```swift
class MockProjectRepository: Repository {
    var projects: [ProjectEntity] = []

    func create(_ entity: ProjectEntity) async throws {
        projects.append(entity)
    }

    func read(id: String) async throws -> ProjectEntity? {
        return projects.first { $0.id == id }
    }

    // ... implement other methods
}
```

## Key Takeaways

1. **Actors**: All data sources are actors for thread-safe concurrency
2. **Repository Pattern**: Abstract data access with Repository protocol
3. **Offline First**: All operations queued and synced when possible
4. **Security**: Sensitive data in Keychain, tokens refreshed
5. **Error Handling**: Graceful error handling with custom error types
6. **Logging**: Comprehensive logging for debugging

## Next Steps

1. Implement DTOs and mappers for API integration
2. Add batch sync optimization
3. Implement push notification sync triggers
4. Add data encryption at rest
5. Create advanced conflict merge strategies
6. Add change tracking/audit logs
7. Implement data export/import
8. Add performance metrics collection

## Resources

- SwiftData Documentation: https://developer.apple.com/documentation/swiftdata
- Swift Concurrency: https://developer.apple.com/documentation/swift/concurrency
- Repository Pattern: https://martinfowler.com/eaaCatalog/repository.html

## Support

For issues or questions about the data layer, check:
1. DATA_LAYER_SCAFFOLD_SUMMARY.md for architecture details
2. Individual file documentation
3. Code comments and function documentation
4. Swift documentation links in headers
