# CLAUDE.md - AI4Science iOS App

## Project Overview

AI4Science is a citizen science iOS application for UTSA's Vision & AI Lab. It enables researchers and citizens to capture, label, and analyze materials science data using on-device machine learning.

**Key Technologies:**
- iOS 26 / Swift 6.2 with strict concurrency
- SwiftUI with Swift Observation (`@Observable`)
- SwiftData for persistence
- CoreML + Vision for on-device ML
- ResearchKit for surveys and consent
- AVFoundation for camera capture
- ARKit for real-time overlays

## Architecture

### Pattern: MVVM + Repository + Clean Architecture

```
Presentation (Features/) → Domain (UseCases/) → Data (Repositories/) → Infrastructure
```

### Layer Responsibilities

| Layer | Purpose | Key Types |
|-------|---------|-----------|
| **Core** | Shared models, protocols, utilities | `User`, `Project`, `Capture`, `Annotation` |
| **Data** | Persistence, API, sync | `*Repository`, `*Entity`, `*Mapper` |
| **Domain** | Business logic | `*UseCase` |
| **Features** | UI + ViewModels | `*View`, `*ViewModel` |
| **Infrastructure** | Platform services | Camera, ML, AR, ResearchKit |
| **UI** | Reusable components | Buttons, Cards, Design System |

## Directory Structure

```
AI4Science/
├── AI4ScienceApp.swift      # App entry point, DI setup
├── Core/
│   ├── App/                 # AppState, NavigationCoordinator, ServiceContainer
│   ├── Models/              # Domain models (User, Project, Sample, etc.)
│   ├── Protocols/           # Repository, UseCase, DataSource protocols
│   └── Extensions/          # Swift type extensions
├── Data/
│   ├── SwiftData/Models/    # @Model entities for persistence
│   ├── Repositories/        # Repository implementations
│   └── Sync/                # Offline sync logic
├── Domain/UseCases/         # Business logic per feature
├── Features/                # MVVM feature modules
│   ├── Auth/
│   ├── Projects/
│   ├── Capture/
│   ├── Analysis/
│   └── ...
├── Infrastructure/          # Platform integrations
│   ├── Camera/
│   ├── ML/
│   ├── AR/
│   └── ResearchKit/
└── UI/
    ├── Components/          # Reusable SwiftUI views
    └── DesignSystem/        # Colors, Typography, Spacing
```

## Swift 6.2 Concurrency Guidelines

### Actor Isolation

- **ViewModels**: Always `@MainActor`
- **Repositories**: Use `@ModelActor` for SwiftData operations
- **Services**: Use `actor` for thread-safe state
- **Models**: Must be `Sendable`

### Patterns to Follow

```swift
// ViewModel pattern
@Observable
@MainActor
final class ProjectsViewModel {
    private let repository: ProjectRepository
    var projects: [Project] = []

    func loadProjects() async {
        projects = try await repository.findAll()
    }
}

// Repository pattern with SwiftData
@ModelActor
final class ProjectRepository {
    func save(_ project: Project) async throws {
        let entity = ProjectMapper.toEntity(project)
        modelContext.insert(entity)
        try modelContext.save()
    }
}

// Service actor pattern
actor CameraManager {
    private var session: AVCaptureSession?

    func startSession() async throws {
        // Thread-safe camera operations
    }
}
```

### Common Async Patterns

```swift
// Use async/await, not completion handlers
func fetchData() async throws -> Data

// Use AsyncStream for continuous data
func frameStream() -> AsyncStream<CMSampleBuffer>

// Use Task groups for parallel work
await withTaskGroup(of: Result.self) { group in
    for id in ids {
        group.addTask { await process(id) }
    }
}
```

## Key Files to Know

| File | Purpose |
|------|---------|
| `AI4ScienceApp.swift` | App entry, SwiftData config, DI setup |
| `Core/App/AppState.swift` | Global app state (auth, sync, errors) |
| `Core/App/ServiceContainer.swift` | Dependency injection container |
| `Core/App/NavigationCoordinator.swift` | Centralized navigation |
| `Core/Models/*.swift` | Domain models |
| `Data/SwiftData/Models/*.swift` | Persistence entities |
| `UI/DesignSystem/*.swift` | Design tokens |

## Coding Conventions

### Naming

- **Files**: `PascalCase.swift` matching the primary type
- **Types**: `PascalCase` (structs, classes, enums, protocols)
- **Properties/Methods**: `camelCase`
- **Protocols**: Noun or `-ing`/`-able` suffix (`Repository`, `Syncable`)

### File Organization

```swift
// 1. Imports
import SwiftUI
import SwiftData

// 2. MARK comments for sections
// MARK: - Properties
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Private Methods

// 3. Extensions at bottom or separate file
extension MyType: Protocol { }
```

### SwiftUI Views

```swift
struct ProjectDetailView: View {
    // 1. Environment
    @Environment(\.modelContext) private var modelContext

    // 2. State
    @State private var viewModel: ProjectDetailViewModel

    // 3. Properties
    let projectId: UUID

    // 4. Body
    var body: some View {
        // View content
    }

    // 5. Subviews (private)
    @ViewBuilder
    private var headerSection: some View { }
}
```

## Common Tasks

### Adding a New Feature

1. Create feature folder: `Features/NewFeature/`
2. Add ViewModel: `Features/NewFeature/ViewModels/NewFeatureViewModel.swift`
3. Add Views: `Features/NewFeature/Views/NewFeatureView.swift`
4. Add navigation destination in `AI4ScienceApp.swift`
5. Add use case if needed: `Domain/UseCases/NewFeature/`
6. Add tests: `AI4ScienceTests/Features/NewFeatureViewModelTests.swift`

### Adding a New Model

1. Add domain model: `Core/Models/NewModel.swift`
2. Add SwiftData entity: `Data/SwiftData/Models/NewModelEntity.swift`
3. Add mapper: `Data/Mappers/NewModelMapper.swift`
4. Add repository: `Data/Repositories/NewModelRepository.swift`
5. Register entity in `AI4ScienceApp.swift` Schema
6. Add tests

### Adding ML Model Integration

1. Add `.mlmodel` to project
2. Create wrapper in `Infrastructure/ML/Models/`
3. Register in `MLModelManager`
4. Add inference method in `MLInferenceEngine`
5. Create use case in `Domain/UseCases/ML/`

## Testing

### Framework: Swift Testing

```swift
import Testing
@testable import AI4Science

@Suite("Project Tests")
struct ProjectTests {

    @Test("Project initializes correctly")
    func testInit() {
        let project = Project(...)
        #expect(project.name == "Test")
    }

    @Test("Async operation completes")
    func testAsync() async throws {
        let result = try await service.fetch()
        #expect(result.count > 0)
    }
}
```

### Test Organization

- `AI4ScienceTests/Core/` - Model tests
- `AI4ScienceTests/Data/` - Repository tests
- `AI4ScienceTests/Domain/` - Use case tests
- `AI4ScienceTests/Features/` - ViewModel tests
- `AI4ScienceTests/Mocks/` - Shared mock objects
- `AI4ScienceTests/Helpers/` - Test utilities

### Running Tests

```bash
# All tests
xcodebuild test -scheme AI4Science -destination 'platform=iOS Simulator,name=iPhone 16'

# Specific test
xcodebuild test -scheme AI4Science -only-testing:AI4ScienceTests/ProjectTests
```

## Dependencies

Currently using only Apple frameworks (no SPM dependencies):
- SwiftUI, SwiftData
- CoreML, Vision, VisionKit
- AVFoundation, ARKit
- ResearchKit (linked framework)

To add SPM dependencies, update `Package.swift` or add via Xcode.

## Build & Run

```bash
# Build
xcodebuild build -scheme AI4Science -destination 'platform=iOS Simulator,name=iPhone 16'

# Run on simulator
xcrun simctl boot "iPhone 16"
xcodebuild build -scheme AI4Science -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Environment

- **Xcode**: 26.2+
- **iOS Deployment Target**: 26.0
- **Swift Version**: 6.2
- **Swift Concurrency**: Strict (`SWIFT_STRICT_CONCURRENCY = complete`)

## Important Patterns

### Error Handling

```swift
// Use AppError for domain errors
enum AppError: LocalizedError {
    case networkUnavailable
    case modelNotFound(String)
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "No internet connection"
        case .modelNotFound(let name): return "Model '\(name)' not found"
        case .validationFailed(let reason): return reason
        }
    }
}

// Handle in ViewModel
func loadData() async {
    do {
        data = try await repository.fetch()
    } catch {
        appState.handleError(AppError.from(error))
    }
}
```

### Navigation

```swift
// Use NavigationCoordinator for programmatic navigation
@Environment(NavigationCoordinator.self) private var navigation

Button("View Details") {
    navigation.showProjectDetail(project.id)
}
```

### Dependency Injection

```swift
// Access via environment
@Environment(ServiceContainer.self) private var services

// Use in ViewModel init
init(repository: ProjectRepository = ServiceContainer.shared.projectRepository)
```

## Offline-First Architecture

The app is designed to work offline:

1. **Local-first**: All data stored in SwiftData
2. **Sync queue**: Changes queued when offline
3. **Conflict resolution**: Last-write-wins with manual override option
4. **ML models**: Downloaded and cached locally

## ResearchKit Integration

For surveys and consent:

```swift
// Create survey task
let task = SurveyTaskFactory.createDemographicsSurvey()

// Present via coordinator
let coordinator = SurveyViewCoordinator(task: task) { result in
    // Handle completion
}
```

## Camera Capture

```swift
// Photo capture
let photo = try await cameraManager.capturePhoto(settings: .highQuality)

// Video recording
try await cameraManager.startRecording(to: outputURL)
// ... later
let video = try await cameraManager.stopRecording()
```

## ML Inference

```swift
// Run defect detection
let detections = try await mlService.runInference(
    on: imageURL,
    modelType: .defectDetection,
    options: .init(confidenceThreshold: 0.7)
)
```

## Notes for AI Assistants

1. **Always use Swift 6.2 concurrency** - async/await, actors, Sendable
2. **Follow MVVM strictly** - ViewModels are @Observable @MainActor
3. **Use SwiftData** - not Core Data or raw SQLite
4. **Prefer composition** - small, focused types
5. **Write tests** - use Swift Testing framework
6. **Use design system** - ColorPalette, Typography, Spacing constants
7. **Handle errors gracefully** - use AppError, show user-friendly messages
8. **Consider offline** - queue sync operations, cache ML models
