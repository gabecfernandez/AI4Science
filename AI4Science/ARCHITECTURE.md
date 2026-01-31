# AI4Science iOS App Architecture

## Overview
AI4Science is a citizen science platform for UTSA's Vision & AI Lab enabling researchers and citizens to capture, label, and analyze materials science data using on-device machine learning.

## Architecture Pattern: MVVM + Repository + Clean Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Views     │  │ ViewModels  │  │   UI Components     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Use Cases  │  │  Entities   │  │  Domain Protocols   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │Repositories │  │  SwiftData  │  │   Data Sources      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   CoreML    │  │   Camera    │  │   ResearchKit       │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Key Technologies
- **iOS 26** / **Swift 6.2** with strict concurrency
- **SwiftData** for persistence
- **SwiftUI** with modern observation
- **CoreML** + **Vision** for on-device ML
- **ResearchKit** for surveys and consent
- **AVFoundation** for camera capture
- **ARKit** for real-time overlays

## Module Structure

### Core
- Models (domain entities)
- Protocols (abstractions)
- Extensions
- Utilities
- Constants

### Data
- SwiftData models
- Repositories (implementations)
- Services (network, sync)
- Data sources

### Domain
- Use cases
- Domain protocols
- Business logic

### Features (per-feature modules)
- Authentication
- Projects
- Capture
- Analysis
- Profile
- Research (ResearchKit)
- Settings

### Infrastructure
- ML (CoreML integration)
- Camera (capture services)
- AR (overlay services)
- Sync (offline-first)

### UI
- Components (reusable views)
- Design System
- Modifiers
- Styles

## Swift 6.2 Concurrency Guidelines
- Use `@MainActor` for all ViewModels
- Use `actor` for data isolation
- Prefer `async/await` over callbacks
- Use `AsyncStream` for continuous data
- Implement `Sendable` conformance properly
