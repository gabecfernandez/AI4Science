# AI4Science Core Layer Architecture

## Overview
Complete Core layer scaffold for the AI4Science iOS app using Swift 6.2 with strict concurrency, Sendable conformance, and modern async/await patterns.

## Directory Structure

```
Core/
├── Models/                    # Domain entities (plain Swift)
│   ├── User.swift            # User with role and affiliation
│   ├── Project.swift         # Research project with status
│   ├── Sample.swift          # Material sample with metadata
│   ├── Capture.swift         # Media capture (photo/video)
│   ├── Annotation.swift      # Defect annotation with bounding box
│   ├── MLModel.swift         # ML model metadata
│   ├── AnalysisResult.swift  # ML analysis results
│   └── SyncStatus.swift      # Sync state enum
│
├── Protocols/                 # Contracts and interfaces
│   ├── Repository.swift      # Generic CRUD protocol
│   ├── UseCase.swift         # Business logic contract
│   ├── DataSource.swift      # Local/remote data operations
│   ├── MLModelProvider.swift # ML model operations
│   ├── CaptureService.swift  # Camera capture contract
│   ├── SyncService.swift     # Offline sync protocol
│   └── Identifiable+Extensions.swift  # Protocol extensions
│
├── Extensions/                # Swift type extensions
│   ├── Date+Extensions.swift      # Date formatting/manipulation
│   ├── URL+Extensions.swift       # File path helpers
│   ├── Data+Extensions.swift      # Encoding/hashing
│   ├── CGRect+Extensions.swift    # Geometry utilities
│   ├── Result+Extensions.swift    # Result type helpers
│   └── Task+Extensions.swift      # Async/await utilities
│
├── Utilities/                 # Support utilities
│   ├── Logger.swift          # Custom logging with os.Logger
│   ├── AppError.swift        # Comprehensive error types
│   ├── Configuration.swift   # App configuration manager
│   ├── FileManager+Helpers.swift  # File operations
│   └── JSONCoder.swift       # Configured encoder/decoder
│
└── Constants/                 # Application constants
    ├── AppConstants.swift    # App-wide constants
    └── FeatureFlags.swift    # Feature flag definitions
```

## Key Features

### Models (Core/Models/)

#### 1. **User.swift**
- Properties: id, email, name, role (citizen/researcher/admin), labAffiliation, timestamps
- Conforms to: Sendable, Codable, Hashable, Identifiable

#### 2. **Project.swift**
- Properties: id, title, description, ownerId, status, timestamps, tags, isPublic
- Status enum: draft, active, completed, archived
- Helper methods: isActive, isCompleted, updateStatus, updateDescription

#### 3. **Sample.swift**
- Properties: id, projectId, name, metadata dictionary, timestamps
- Helper methods: updateMetadata, removeMetadata, metadataDescription

#### 4. **Capture.swift**
- Properties: id, sampleId, type, localURL, timestamp, annotations, metadata, syncStatus
- Type enum: photo, video
- Custom Codable implementation for URL handling
- Helper methods: isPhoto, isVideo, isSynced, annotation management

#### 5. **Annotation.swift**
- Nested types: DefectType (crack, corrosion, etc.), BoundingBox
- Properties: id, captureId, type, boundingBox, confidence, notes
- Helper methods: confidencePercentage, confidence level checks
- Annotation utilities: normalize to size, area calculation

#### 6. **MLModel.swift**
- Properties: id, name, version, type, description, localPath, isDownloaded, fileSize, timestamps
- Type enum: classification, detection, segmentation, regression
- Custom Codable for URL handling
- Helper methods: displayName, fileSizeInMB, version updates

#### 7. **AnalysisResult.swift**
- Nested types: Prediction (with AnyCodable support), AnyCodable (flexible JSON)
- Properties: id, captureId, modelId, predictions, processingTime, timestamp, metadata
- Helper methods: topPrediction, topConfidence, topLabel, filtering by threshold

#### 8. **SyncStatus.swift**
- Enum cases: pending, syncing, synced, failed
- Helper properties: isPending, isSyncing, isSynced, isFailed, needsSync

### Protocols (Core/Protocols/)

#### 1. **Repository.swift**
- Generic repository with CRUD operations
- Methods: fetch, fetchAll, create, update, delete, deleteAll, exists, count
- Specialized: ProjectRelatedRepository, CaptureRelatedRepository

#### 2. **UseCase.swift**
- Generic UseCase<Input, Output>
- Variants: VoidInputUseCase, VoidOutputUseCase, VoidUseCase
- All async/throws returning

#### 3. **DataSource.swift**
- LocalDataSource: Local storage operations
- RemoteDataSource: API operations
- CachedDataSource: Combined local/remote with cache invalidation

#### 4. **MLModelProvider.swift**
- Model operations: download, load, unload, check, list, verify
- Inference provider: inferImage, inferBatch, getCapabilities
- ModelCapabilities struct with GPU/Neural Engine support info

#### 5. **CaptureService.swift**
- Enums: CameraPosition (front/back), FlashMode, VideoQuality
- Camera availability and permission checks
- Photo and video capture with metadata
- Torch control and camera enumeration

#### 6. **SyncService.swift**
- Enums: SyncDirection, SyncError
- SyncOperation struct with tracking
- Operations: syncAll, sync specific, status checking, history, retry, cancellation
- Handlers: onSyncStatusChanged, getLastSyncTime

#### 7. **Identifiable+Extensions.swift**
- IDComparable: ID-based comparison
- Timestamped: Age tracking and recency checks
- Syncable: Sync state tracking

### Extensions (Core/Extensions/)

#### 1. **Date+Extensions.swift**
- Formatting: iso8601String, formatted(format:), relative time strings
- Predicates: isToday, isYesterday, isTomorrow
- Arithmetic: addingDays, addingHours, addingMinutes
- Components: year, month, day, hour, minute, second, weekday

#### 2. **URL+Extensions.swift**
- Directory shortcuts: documentsDirectory, cacheDirectory, temporaryDirectory, applicationSupportDirectory
- Directory operations: create if needed, exists checks, is directory/file
- File operations: copy, move, delete, size calculation, creation/modification dates
- Content access: directoryContents, directoryContentsRecursive, filesWithExtension

#### 3. **Data+Extensions.swift**
- Encoding: hexString, base64String
- Hashing: md5Hash, sha256Hash
- Compression: gzipCompressed, gzipDecompressed
- Utilities: isValidUTF8, toString, sizeInKB/MB, byte counting

#### 4. **CGRect+Extensions.swift**
- Normalization: denormalized, normalized
- Geometry: center, area, aspectRatio
- Transformations: expanded, insetted, scaled, offset
- Utilities: isValid, clamp, fit, aspectFill, intersection
- CGSize and CGPoint extensions for geometry helpers

#### 5. **Result+Extensions.swift**
- Accessors: value, error, isSuccess, isFailure
- Transformations: map, mapError, flatMap
- Operations: getOrElse, onSuccess, onFailure, recover
- Combiners: combine 2-3 results, description

#### 6. **Task+Extensions.swift**
- TaskCancellationToken: Actor-based cancellation
- Task modifiers: withTimeout, withRetry, catch, finally
- Sleep variants: sleep(for:), sleepMilliseconds, sleepSeconds
- TaskGroup: addTasks batch operation

### Utilities (Core/Utilities/)

#### 1. **Logger.swift**
- LogLevel enum: debug, info, warning, error
- Category enum: general, network, database, mlModel, sync, capture, auth
- Shared actor instance with configurable minimum level
- Async-safe logging using os.log
- Global convenience functions: logDebug, logInfo, logWarning, logError

#### 2. **AppError.swift**
- Comprehensive error hierarchy with subtypes
- Categories: invalidInput, notFound, duplicateEntry, validationFailed
- Network errors, storage errors, authentication, ML, camera, sync, file errors
- Localizable error descriptions, failure reasons, recovery suggestions
- Helper properties: isNetworkError, isAuthenticationError, isTimeout, etc.
- Conversion from URLError, DecodingError, EncodingError

#### 3. **Configuration.swift**
- APIEndpoints struct with configurable paths
- NetworkConfig: timeouts, retries, logging
- StorageConfig: cache sizes, expiration, cloud sync
- FeatureFlags struct for feature toggles
- Environment enum: development, staging, production
- Initialization methods for each environment
- Async getters for thread-safe access

#### 4. **FileManager+Helpers.swift**
- Document directory helpers: save, load, delete
- Cache directory helpers: save, load, delete, clearAll
- Directory operations: create if needed, size calculation, remove old files
- File operations: exists, copy, move, size, modification date
- Disk space utilities: availableDiskSpace, totalDiskSpace

#### 5. **JSONCoder.swift**
- Pre-configured JSONEncoder and JSONDecoder
- ISO8601 dates, base64 data, pretty printing, sorted keys
- Encoding methods: encode, encodeCompact, encodeToString
- Decoding methods: decode, decodeFromString, decodeFromFile, decodeArray
- Validation: isValidJSON, getJSONType
- Convenience extensions on Encodable/Decodable

### Constants (Core/Constants/)

#### 1. **AppConstants.swift**
- Bundle: appName, bundleIdentifier, version, buildNumber
- UserDefaults keys
- Keychain keys
- Database settings
- Directory names: Captures, Projects, MLModels, Cache, Temp, Annotations, Analysis
- Network timeouts (default, upload, download, model)
- Cache settings (sizes, expiration)
- Image settings (dimensions, compression, file size limits)
- Video settings (duration, bitrate, sample rate)
- ML Model settings (cache, concurrent models, timeout)
- Sync settings (interval, retries, backoff)
- UI settings (corner radius, padding, animation duration)
- Validation rules (password length, name lengths)
- Error codes by category
- Notification names
- Date format strings

#### 2. **FeatureFlags.swift**
- Actor-based singleton for thread-safe flag management
- 24 feature flags organized by category
- Core: offline mode, cloud sync, analytics, crash reporting
- ML: advanced ML, on-device inference, batch inference, auto-annotation
- Camera: multi-camera, torch, video, live preview
- Data: cloud backup, compression, encryption, differential sync
- UI: dark mode, landscape, tablet UI, custom theme
- Experimental: beta features, debug menu, performance metrics
- Getters: all async to support actor isolation
- Setters: all async
- Preset configurations: development, staging, production
- resetToDefaults, getAllFlags for debugging

## Design Patterns

### Strict Concurrency
- All protocols marked Sendable
- Actor usage for Logger, Configuration, FeatureFlags
- Async/await throughout
- Proper use of @Sendable closures

### Type Safety
- Strong typing with enums for state
- Codable conformance for serialization
- Identifiable for collection management
- Hashable for Set/Dictionary keys

### Error Handling
- Comprehensive AppError enum with categories
- LocalizedError conformance
- Conversion from system errors
- Descriptive failure reasons and recovery suggestions

### Architecture
- Clean separation: Models, Protocols, Extensions, Utilities, Constants
- Generic protocols for flexibility
- Repository pattern for data access
- UseCase pattern for business logic
- Service protocols for operations

## Sendable Conformance

All models and protocols conform to Sendable:
- Frozen enums for all value types
- Value types (structs) for models
- Explicit Sendable conformance declarations
- Actor types for shared mutable state

## Swift 6.2 Features

- Strict concurrency mode ready
- Async/await throughout
- Sendable conformance
- Modern error handling
- Swift 6 effective concurrency patterns
- Type-safe Date handling
- Generic constraint improvements

## File Locations

```
/sessions/optimistic-beautiful-ramanujan/mnt/AI4Science/AI4Science/Core/
├── Constants/AppConstants.swift
├── Constants/FeatureFlags.swift
├── Extensions/CGRect+Extensions.swift
├── Extensions/Data+Extensions.swift
├── Extensions/Date+Extensions.swift
├── Extensions/Result+Extensions.swift
├── Extensions/Task+Extensions.swift
├── Extensions/URL+Extensions.swift
├── Models/AnalysisResult.swift
├── Models/Annotation.swift
├── Models/Capture.swift
├── Models/MLModel.swift
├── Models/Project.swift
├── Models/Sample.swift
├── Models/SyncStatus.swift
├── Models/User.swift
├── Protocols/CaptureService.swift
├── Protocols/DataSource.swift
├── Protocols/Identifiable+Extensions.swift
├── Protocols/MLModelProvider.swift
├── Protocols/Repository.swift
├── Protocols/SyncService.swift
├── Protocols/UseCase.swift
├── Utilities/AppError.swift
├── Utilities/Configuration.swift
├── Utilities/FileManager+Helpers.swift
├── Utilities/JSONCoder.swift
└── Utilities/Logger.swift
```

Total: 28 files, ~4000+ lines of production-ready code
