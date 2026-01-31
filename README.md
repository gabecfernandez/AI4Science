# AI4Science

<p align="center">
  <img src="https://img.shields.io/badge/iOS-26%2B-blue" alt="iOS 26+">
  <img src="https://img.shields.io/badge/Swift-6.2-orange" alt="Swift 6.2">
  <img src="https://img.shields.io/badge/SwiftUI-Observation-green" alt="SwiftUI">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey" alt="License">
</p>

A citizen science iOS application developed by **UTSA's Vision & AI Lab** that enables researchers and citizens to capture, label, and analyze materials science data using on-device machine learning.

## Overview

AI4Science bridges the gap between laboratory research and citizen science by providing a mobile platform for materials analysis. Scientists can design studies, while participants capture high-quality images of materials, annotate defects, and contribute to research—all with real-time AI assistance running entirely on-device.

### Key Capabilities

- **📸 High-Quality Capture** — Photo and video capture optimized for materials science with RAW support
- **🤖 On-Device ML** — Defect detection and classification using CoreML, optimized for Neural Engine
- **🏷️ Smart Annotation** — AI-assisted labeling with multiple annotation types (points, rectangles, polygons, freeform)
- **📊 Real-Time Analysis** — Instant feedback on captured samples with confidence scores
- **🔬 ResearchKit Integration** — Surveys, consent flows, and study management for citizen science
- **📡 Offline-First** — Full functionality without internet; sync when connected
- **🎯 AR Overlays** — Real-time defect visualization using ARKit

## Requirements

- **iOS 26.0+**
- **Xcode 26.2+**
- **Swift 6.2**
- iPhone with A12 Bionic or later (for Neural Engine ML acceleration)

## Getting Started

### Clone the Repository

```bash
git clone git@github.com:gabecfernandez/AI4Science.git
cd AI4Science
```

### Open in Xcode

```bash
open AI4Science.xcodeproj
```

### Build & Run

1. Select your target device or simulator
2. Press `Cmd + R` to build and run

### Running Tests

```bash
xcodebuild test \
  -scheme AI4Science \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

AI4Science follows **MVVM + Repository + Clean Architecture** with strict separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│         Views (SwiftUI) ←→ ViewModels (@Observable)         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│              Use Cases • Business Logic                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│         Repositories • SwiftData • Mappers • Sync           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                      │
│        Camera • ML • AR • ResearchKit • Network             │
└─────────────────────────────────────────────────────────────┘
```

### Project Structure

```
AI4Science/
├── Core/                   # Shared models, protocols, utilities
│   ├── Models/            # Domain models (User, Project, Sample, etc.)
│   ├── Protocols/         # Repository, UseCase, Service protocols
│   └── Extensions/        # Swift type extensions
├── Data/                   # Data persistence layer
│   ├── SwiftData/         # @Model entities
│   ├── Repositories/      # Data access implementations
│   └── Sync/              # Offline sync coordination
├── Domain/                 # Business logic
│   └── UseCases/          # Feature-specific use cases
├── Features/               # MVVM feature modules
│   ├── Auth/              # Authentication
│   ├── Projects/          # Project management
│   ├── Capture/           # Camera & capture
│   ├── Analysis/          # ML analysis results
│   └── ...
├── Infrastructure/         # Platform services
│   ├── Camera/            # AVFoundation integration
│   ├── ML/                # CoreML + Vision
│   ├── AR/                # ARKit overlays
│   └── ResearchKit/       # Survey & consent
└── UI/                     # Reusable components
    ├── Components/        # Buttons, Cards, Inputs, etc.
    └── DesignSystem/      # Colors, Typography, Spacing
```

## Features

### For Researchers

- **Study Design** — Create projects with custom protocols and consent flows
- **Sample Management** — Organize materials by project, batch, and metadata
- **Data Export** — Export annotations and analysis results in JSON, CSV, or ZIP formats
- **NSF FAIR Compliance** — Built-in support for open science data standards
- **Lab Affiliation** — Connect with UTSA labs and research groups

### For Citizen Scientists

- **Guided Capture** — Step-by-step instructions for capturing quality images
- **AI Assistance** — Real-time defect detection helps identify areas of interest
- **Progress Tracking** — See contribution history and impact
- **Offline Mode** — Capture and annotate without internet connection
- **ResearchKit Surveys** — Participate in research studies

### Machine Learning

The app includes on-device ML models for:

| Model | Purpose | Input |
|-------|---------|-------|
| DefectDetector | Identify material defects | 640×640 image |
| MaterialClassifier | Classify material types | 224×224 image |
| Segmentation | Pixel-level defect masks | 512×512 image |

All models run locally using CoreML with Neural Engine optimization—no data leaves the device.

## Swift Concurrency

AI4Science is built with Swift 6.2's strict concurrency from the ground up:

```swift
// ViewModels are @MainActor isolated
@Observable
@MainActor
final class ProjectsViewModel {
    private let repository: ProjectRepository
    var projects: [Project] = []

    func loadProjects() async {
        projects = try await repository.findAll()
    }
}

// Services use actor isolation
actor CameraManager {
    private var session: AVCaptureSession?

    func startSession() async throws {
        // Thread-safe camera operations
    }
}
```

## Configuration

### Environment Variables

Create a `.env` file for local development:

```bash
# API Configuration (optional - app works offline)
API_BASE_URL=https://api.ai4science.utsa.edu
API_VERSION=v1

# Feature Flags
ENABLE_AR_OVERLAY=true
ENABLE_CLOUD_SYNC=false
```

### Build Configurations

| Configuration | Purpose |
|---------------|---------|
| Debug | Development with verbose logging |
| Release | Production build with optimizations |

## Testing

The project uses **Swift Testing** framework:

```swift
@Suite("Project Tests")
struct ProjectTests {

    @Test("Project initializes with correct status")
    func testProjectInit() {
        let project = Project(name: "Test", ownerId: UUID())
        #expect(project.status == .draft)
    }

    @Test("Repository saves and retrieves")
    @MainActor
    func testRepositoryCRUD() async throws {
        let repo = MockProjectRepository()
        let project = Project(name: "Test", ownerId: UUID())

        try await repo.save(project)
        let retrieved = try await repo.findById(project.id)

        #expect(retrieved?.name == "Test")
    }
}
```

### Test Coverage

- **Core/** — Model validation, serialization
- **Data/** — Repository CRUD operations
- **Domain/** — Use case business logic
- **Features/** — ViewModel state management
- **Infrastructure/** — Service integration

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Swift API Design Guidelines
- Use `@MainActor` for all ViewModels
- Prefer `async/await` over callbacks
- Write tests for new features

## Documentation

- [ARCHITECTURE.md](AI4Science/ARCHITECTURE.md) — Detailed architecture overview
- [CLAUDE.md](CLAUDE.md) — AI assistant guidance for the codebase

## Research & Publications

This app supports research at UTSA's Vision & AI Lab. If you use AI4Science in your research, please cite:

```bibtex
@software{ai4science2026,
  title = {AI4Science: Mobile Citizen Science for Materials Analysis},
  author = {Fernandez, Gabriel and UTSA Vision & AI Lab},
  year = {2026},
  url = {https://github.com/gabecfernandez/AI4Science}
}
```

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **UTSA Vision & AI Lab** — Research direction and domain expertise
- **Apple** — SwiftUI, SwiftData, CoreML, ResearchKit frameworks
- **NSF** — Support for open science initiatives

