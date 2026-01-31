# AI4Science Data Layer Architecture Guide

## Overview

The Data layer implements a clean, thread-safe architecture using SwiftData for local persistence, with support for remote synchronization. All components follow Swift 6.2 strict concurrency rules using actors for thread safety.

## Directory Structure

```
Data/
├── SwiftData/
│   ├── Models/
│   │   ├── UserEntity.swift              # User persistence model
│   │   ├── ProjectEntity.swift           # Project persistence model
│   │   ├── SampleEntity.swift            # Sample persistence model
│   │   ├── CaptureEntity.swift           # Capture persistence model
│   │   ├── AnnotationEntity.swift        # Annotation persistence model
│   │   ├── MLModelEntity.swift           # ML Model persistence model
│   │   ├── AnalysisResultEntity.swift    # Analysis Result persistence model
│   │   └── SyncQueueEntity.swift         # Sync Queue persistence model
│   ├── ModelContainer+Configuration.swift # SwiftData container setup
│   └── SchemaVersions.swift              # Schema versioning and migrations
├── Repositories/
│   ├── UserRepository.swift              # User repository
│   ├── ProjectRepository.swift           # Project repository
│   ├── SampleRepository.swift            # Sample repository
│   ├── CaptureRepository.swift           # Capture repository
│   ├── AnnotationRepository.swift        # Annotation repository
│   ├── MLModelRepository.swift           # ML Model repository
│   ├── AnalysisRepository.swift          # Analysis repository
│   └── SyncQueueRepository.swift         # Sync Queue repository
├── DataSources/
│   ├── LocalDataSource.swift             # Local data source protocols
│   ├── RemoteDataSource.swift            # Remote data source protocols
│   ├── APIClient.swift                   # Network client with async/await
│   └── APIEndpoints.swift                # API endpoint definitions
├── Mappers/
│   ├── UserMapper.swift                  # User DTO<->Entity mapping
│   ├── ProjectMapper.swift               # Project DTO<->Entity mapping
│   ├── CaptureMapper.swift               # Capture DTO<->Entity mapping
│   └── AnnotationMapper.swift            # Annotation DTO<->Entity mapping
└── DATA_LAYER_GUIDE.md                   # This file
```

## Architecture Components

### 1. SwiftData Models (@Model)

All persistence models use the `@Model` macro and feature:
- Unique identifier with `@Attribute(.unique)` decorator
- Relationships with cascade delete rules
- Helper methods for common operations
- @MainActor isolation for UI-related updates
- Support for nested entities (e.g., ProjectMetadata, SampleProperties)

#### Key Models:
- **UserEntity**: User authentication and profile data
- **ProjectEntity**: Research projects with sample relationships
- **SampleEntity**: Physical/digital samples in projects
- **CaptureEntity**: Captures (images, videos, scans) of samples
- **AnnotationEntity**: Annotations and markups on captures
- **MLModelEntity**: Downloadable ML models for analysis
- **AnalysisResultEntity**: Results from ML model execution
- **SyncQueueEntity**: Offline operation queue for syncing

### 2. Repositories (Actor-based)

Each repository is implemented as an actor for thread-safe database operations:

```swift
actor UserRepository: UserRepositoryProtocol {
    private let modelContext: ModelContext

    func createUser(_ user: UserEntity) async throws
    func getUser(id: String) async throws -> UserEntity?
    func updateUser(_ user: UserEntity) async throws
    func deleteUser(id: String) async throws
    // ... more operations
}
```

**Repository Pattern Benefits:**
- Single responsibility for entity CRUD operations
- Abstraction layer between business logic and persistence
- Easy to test and mock
- Consistent error handling with `RepositoryError`

### 3. Data Sources

#### LocalDataSource
- Protocol-based design for local persistence
- Generic actor implementation
- Methods: create, read, update, delete, readAll

#### RemoteDataSource
- Protocol-based design for remote API calls
- Specific implementations for each entity type
- Methods: create, read, update, delete, readAll with pagination

#### APIClient (Actor)
- Async/await based HTTP client
- Built-in error handling with `APIError` enum
- JSON encoding/decoding with custom date strategies
- Request/response validation
- Configurable timeout and retry logic

### 4. Mappers

Mappers handle conversions between three representations:

1. **Entity** (SwiftData @Model) - Database persistence
2. **DTO** (Data Transfer Object) - API communication
3. **Domain Model** (Struct) - Business logic representation

```swift
struct UserMapper {
    static func toDTO(_ entity: UserEntity) -> UserDTO
    static func toEntity(_ dto: UserDTO) -> UserEntity
    static func toModel(_ entity: UserEntity) -> User
    static func update(_ entity: UserEntity, with dto: UserDTO)
}
```

## Thread Safety & Actor Isolation

All database operations follow Swift 6.2 strict concurrency:

```swift
// Repositories are actors - only one async task at a time
actor UserRepository {
    func getUser(id: String) async throws -> UserEntity?
    func updateUser(_ user: UserEntity) async throws
}

// Model entities use @MainActor for UI operations
@Model
class UserEntity {
    @MainActor
    func updateInfo(fullName: String? = nil) { ... }
}

// APIClient is an actor for network operations
actor APIClient {
    func get<T: Decodable>(endpoint: String) async throws -> T
    func post<T: Encodable, R: Decodable>(endpoint: String, body: T) async throws -> R
}
```

## ModelContainer Configuration

The `ModelContainer+Configuration` extension provides:

```swift
// Production container
let container = try ModelContainer.makeAI4ScienceContainer()

// Preview container for SwiftUI
let previewContainer = try ModelContainer.previewContainer()
```

Features:
- Automatic schema setup with all models
- Migration plan for schema evolution
- In-memory option for testing
- Automatic sample data generation for previews

## API Endpoints

Centralized endpoint definitions in `APIEndpoints`:

```swift
APIEndpoints.users              // GET /v1/users
APIEndpoints.project(id: "123") // GET /v1/projects/123
APIEndpoints.uploadCapture      // POST /v1/captures/upload
```

Benefits:
- Single source of truth for API paths
- Type-safe endpoint construction
- Support for query parameters and pagination
- Organized by resource type

## Error Handling

### RepositoryError
```swift
enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed
    case deleteFailed
    case invalidData
    case networkError
}
```

### APIError
```swift
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case encodingError
    case networkError(Error)
    case serverError(statusCode: Int)
    case unauthorized
    case notFound
    case serverUnavailable
}
```

## Usage Examples

### Creating and Saving Data

```swift
let context = ModelContext(container)
let repo = UserRepository(modelContext: context)

let newUser = UserEntity(
    id: UUID().uuidString,
    email: "user@example.com",
    fullName: "John Doe"
)

try await repo.createUser(newUser)
```

### Fetching Data

```swift
let user = try await repo.getUser(id: "user123")
let projects = try await projectRepo.getProjectsByOwner(userID: "user123")
let activeProjects = try await projectRepo.getProjectsByStatus("active")
```

### Updating Data

```swift
user.updateInfo(fullName: "Jane Doe")
try await repo.updateUser(user)
```

### Searching

```swift
let results = try await projectRepo.searchProjects(query: "microscopy")
let samples = try await sampleRepo.getSamplesByType("tissue")
```

### Offline Sync Queue

```swift
let queueEntry = SyncQueueEntity(
    id: UUID().uuidString,
    operationType: "create",
    entityType: "project",
    entityID: project.id,
    operationData: jsonData
)

try await syncQueueRepo.addToQueue(queueEntry)

// Retry with exponential backoff
if queueEntry.shouldRetry {
    try await Task.sleep(nanoseconds: UInt64(queueEntry.retryWaitTime * 1_000_000_000))
    // Retry operation
}
```

## SwiftUI Integration

### With @Environment

```swift
@Environment(\.modelContext) var modelContext

let repo = UserRepository(modelContext: modelContext)
let users = try await repo.getAllUsers()
```

### With @Query

```swift
@Query var projects: [ProjectEntity]

// Automatically updates when data changes
```

### Preview Support

```swift
#Preview {
    MyView()
        .modelContainer(
            try! ModelContainer.previewContainer()
        )
}
```

## Migration Strategy

Schema versions are managed in `SchemaVersions.swift`:

```swift
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = "v1"

    static var models: [any PersistentModel.Type] {
        [UserEntity.self, ProjectEntity.self, ...]
    }
}

enum SchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        [] // Add migration stages as schema evolves
    }
}
```

## Testing Considerations

### Unit Testing
```swift
// Use in-memory container
let container = try ModelContainer(
    for: Schema([UserEntity.self]),
    isStoredInMemoryOnly: true
)

let repo = UserRepository(modelContext: ModelContext(container))
let user = try await repo.getUser(id: "test123")
```

### Integration Testing
- Use preview container with sample data
- Test entire workflows
- Verify relationships and cascading deletes

## Performance Optimization

1. **Fetch Descriptors**: Use predicates to limit queries
2. **Sorting**: Always sort consistently for pagination
3. **Relationships**: Use cascade delete strategically
4. **Batching**: Process multiple operations together when possible
5. **Caching**: Consider caching frequently accessed data

## Security Best Practices

1. **Secure Storage**: Auth tokens should use Keychain (not shown in this scaffold)
2. **Data Validation**: Validate input in repositories
3. **API Authentication**: Add auth headers in APIClient
4. **Encryption**: Consider encrypting sensitive data at rest
5. **Access Control**: Use Swift access modifiers appropriately

## Future Enhancements

1. **Caching Layer**: Add in-memory cache for frequent queries
2. **Conflict Resolution**: Handle sync conflicts intelligently
3. **Encryption**: Implement at-rest encryption for sensitive data
4. **Batch Operations**: Add bulk create/update/delete
5. **Real-time Sync**: Implement WebSocket for real-time updates
6. **Offline-First**: Enhance offline functionality
7. **Analytics**: Add data access logging and analytics

## Dependencies

- SwiftData (iOS 17+, included in scaffold)
- Foundation (async/await)
- URLSession (networking)

## Compatibility

- iOS 17.0+
- Swift 6.2+
- Strict Concurrency enabled

## Notes

- All async operations use async/await syntax
- All database operations are actor-isolated
- All network operations use URLSession
- Relationships use cascade delete rules
- Dates use ISO8601 encoding/decoding
- Errors are strongly typed for better error handling
