# ML Infrastructure Layer Summary

Complete ML Infrastructure scaffold for AI4Science iOS app with on-device ML capabilities, Vision framework integration, and Apple Intelligence features.

## Directory Structure

```
Infrastructure/
├── ML/
│   ├── Services/
│   │   ├── MLModelManager.swift
│   │   ├── DefectDetectionService.swift
│   │   ├── ImageClassificationService.swift
│   │   ├── ObjectDetectionService.swift
│   │   └── ModelDownloadService.swift
│   ├── Processors/
│   │   ├── ImagePreprocessor.swift
│   │   ├── VideoFrameProcessor.swift
│   │   ├── ResultPostprocessor.swift
│   │   └── ConfidenceFilter.swift
│   ├── Models/
│   │   ├── MLModelWrapper.swift
│   │   ├── VisionModelWrapper.swift
│   │   ├── PredictionResult.swift
│   │   └── BoundingBox.swift
│   └── Configuration/
│       ├── MLConfiguration.swift
│       └── ModelRegistry.swift
├── Vision/
│   ├── VisionService.swift
│   ├── ImageAnalyzer.swift
│   ├── TextRecognitionService.swift
│   └── BarcodeScanner.swift
└── AppleIntelligence/
    ├── AppleIntelligenceService.swift
    ├── SmartSuggestionsProvider.swift
    └── NaturalLanguageProcessor.swift
```

## Core Components

### ML Services Layer

#### MLModelManager.swift
- **Actor**: Thread-safe model lifecycle management
- **Capabilities**:
  - Load CoreML models with caching
  - Manage model cache with LRU eviction
  - Configure compute units (Neural Engine, GPU, CPU)
  - Handle model compilation
  - Concurrent model loading

#### DefectDetectionService.swift
- **Actor**: Specialized defect detection
- **Features**:
  - Single and batch defect detection
  - Real-time streaming detection from video frames
  - Severity level classification
  - Confidence-based filtering
  - AsyncStream for continuous inference

#### ImageClassificationService.swift
- **Actor**: Image classification service
- **Capabilities**:
  - Single and batch classification
  - Top-K predictions
  - Confidence thresholding
  - Video frame streaming
  - Multiple image analysis

#### ObjectDetectionService.swift
- **Actor**: Object detection with bounding boxes
- **Features**:
  - Single and batch detection
  - Non-Maximum Suppression (NMS)
  - Class-specific filtering
  - Detection statistics
  - Real-time video streaming

#### ModelDownloadService.swift
- **Actor**: Remote model management
- **Capabilities**:
  - Download models from remote URLs
  - Local caching and versioning
  - Concurrent downloads
  - Progress tracking
  - Cache management with size limits

### Data Processing Layer

#### ImagePreprocessor.swift
- **Actor**: Image preparation for inference
- **Functions**:
  - Image resizing (with aspect ratio preservation)
  - Normalization (mean/std)
  - Pixel buffer conversion
  - Batch preprocessing
  - Model input dimension detection

#### VideoFrameProcessor.swift
- **Actor**: Video frame extraction and processing
- **Capabilities**:
  - AVCapture video setup
  - Frame sampling and interval extraction
  - Frame rotation and resizing
  - Normalization
  - Thumbnail generation
  - Batch frame processing

#### ResultPostprocessor.swift
- **Actor**: ML output parsing
- **Features**:
  - Classification output parsing
  - Object detection output parsing
  - Defect detection parsing
  - Semantic segmentation parsing
  - Result aggregation and filtering

#### ConfidenceFilter.swift
- **Actor**: Prediction filtering
- **Capabilities**:
  - Confidence thresholding
  - Probability distance filtering
  - Non-Maximum Suppression (IoU-based)
  - Class filtering
  - Statistical outlier detection
  - Adaptive thresholding
  - Defect clustering

### Model Abstraction Layer

#### MLModelWrapper.swift
- **Protocol**: Unified ML model interface
- **Features**:
  - Standard model wrapper protocol
  - Model metadata structure
  - Performance information
  - Model factory pattern
  - Device capability detection

#### VisionModelWrapper.swift
- **Class**: Vision framework integration
- **Capabilities**:
  - VNCoreMLModel wrapping
  - Vision request creation
  - Batch processing support
  - Real-time video frame handling
  - Model specification inspection
  - Performance optimization

#### PredictionResult.swift
- **Struct**: Standardized prediction format
- **Components**:
  - Unified prediction result type
  - Multiple output format support
  - Confidence information
  - Input metadata tracking
  - Prediction builder pattern
  - Batch result aggregation

#### BoundingBox.swift
- **Struct**: Normalized bounding box handling
- **Operations**:
  - Normalized coordinates (0-1)
  - Pixel coordinate conversion
  - IoU calculation
  - Box containment checking
  - Box intersection detection
  - Expansion/shrinking operations
  - Rotation support
  - Boundary clipping
  - Safe array indexing

### Configuration Layer

#### MLConfiguration.swift
- **Struct**: ML compute unit preferences
- **Features**:
  - Compute unit selection (Neural Engine, GPU, CPU)
  - Batch processing configuration
  - Memory optimization settings
  - Performance monitoring setup
  - Preset configurations (Performance, Balanced, Efficiency)
  - Device capability detection

#### ModelRegistry.swift
- **Actor**: Model metadata registry
- **Capabilities**:
  - Model registration and retrieval
  - Model grouping and categorization
  - Search functionality
  - Dependency tracking
  - Version management
  - Registry statistics
  - Default model loading

## Vision Framework Integration

### VisionService.swift
- **Actor**: Core Vision framework operations
- **Features**:
  - Face detection with landmarks
  - Feature point detection
  - Scene classification
  - Image quality analysis
  - Horizontal/vertical alignment detection
  - Document boundary detection
  - Blur and brightness metrics

### ImageAnalyzer.swift
- **Actor**: Comprehensive image analysis
- **Capabilities**:
  - Complete image analysis workflow
  - Focused analysis by area
  - Batch image processing
  - Real-time video streaming
  - Image comparison and similarity
  - Region of interest analysis

### TextRecognitionService.swift
- **Actor**: OCR and text extraction
- **Features**:
  - Text recognition in images
  - Structured text extraction
  - Region-based text recognition
  - Text search functionality
  - Document text extraction
  - Sample label recognition
  - Batch OCR processing
  - Real-time video OCR

### BarcodeScanner.swift
- **Actor**: Barcode and QR code detection
- **Capabilities**:
  - Multi-format barcode detection
  - QR code detection and parsing
  - UPC/EAN code detection with validation
  - Code128 detection (lab-specific)
  - Real-time video scanning
  - Batch scanning
  - VCARD parsing from QR codes
  - URL extraction from QR codes

## Apple Intelligence Integration

### AppleIntelligenceService.swift
- **Actor**: Apple Intelligence features
- **Capabilities**:
  - Feature availability checking
  - Text processing with entity extraction
  - Smart suggestion generation
  - Context-aware analysis
  - Batch text processing
  - Privacy information
  - iOS 18+ compatibility

### SmartSuggestionsProvider.swift
- **Actor**: Context-aware suggestions
- **Features**:
  - Smart suggestion caching
  - Context-specific suggestions
  - Suggestion ranking and filtering
  - ML-based scoring
  - User feedback tracking
  - Learning from selections/rejections
  - Multi-context batch processing

### NaturalLanguageProcessor.swift
- **Actor**: Natural Language processing
- **Capabilities**:
  - Named entity extraction
  - Language detection
  - Sentiment analysis
  - Keyword extraction
  - Text summarization
  - Text tokenization (words/sentences)
  - Text classification
  - Language hypothesis ranking

## Key Design Patterns

### Thread Safety
- **Actors**: All services use Swift actors for thread-safe concurrent access
- **Isolation**: Data is isolated by actor boundaries
- **Sendable Types**: All result types conform to Sendable for safe data passing

### Async/Await
- **AsyncStream**: Real-time inference with continuous streams
- **Task Groups**: Concurrent batch processing
- **Sequential Operations**: Dependent operations properly ordered

### Resource Management
- **Caching**: Model cache with LRU eviction (ML, suggestions)
- **Memory Optimization**: Configurable memory limits
- **Cleanup**: Proper actor unloading and cleanup

### Error Handling
- **Custom Errors**: Specific error types for each layer
- **Recovery Suggestions**: User-friendly error information
- **Graceful Degradation**: Fallback options (CPU when GPU unavailable)

## Performance Optimization

### Neural Engine Support
- Automatic Neural Engine utilization for supported devices
- Fallback to GPU and CPU when needed
- Low precision accumulation on GPU
- Batch processing support

### Model Caching
- In-memory caching of loaded models
- LRU eviction when cache full
- Download caching for remote models
- Statistics and monitoring

### Preprocessing Optimization
- Efficient image resizing with proper aspect ratio
- Batch preprocessing support
- Memory-mapped video frame access
- Pixel buffer optimization

## Integration Points

### With Domain Layer
- DefectDetectionService integrates with domain defect models
- Classification results map to domain categories
- Detection results map to domain analysis findings

### With Data Layer
- ModelDownloadService coordinates with persistence
- Model registry provides available models
- Cache statistics for storage planning

### With UI Layer
- AsyncStream results feed directly to SwiftUI
- Real-time updates for video processing
- Confidence scores for user feedback

## Usage Examples

### Basic Image Classification
```swift
let classifier = ImageClassificationService()
try await classifier.initialize()
let results = try await classifier.classify(image: uiImage)
```

### Real-time Defect Detection
```swift
let detector = DefectDetectionService()
try await detector.initialize()

let stream = videoProcessor.startVideoCapture()
let defectStream = await detector.streamDefectDetection(from: stream)

for await frame in defectStream {
    // Handle defect predictions in real-time
}
```

### Smart Suggestions
```swift
let provider = SmartSuggestionsProvider()
let suggestions = try await provider.generateLabelSuggestions(for: "Sample")
```

### Text & Barcode Recognition
```swift
let textService = TextRecognitionService()
let text = try await textService.recognizeSampleLabel(from: labelImage)

let barcode = BarcodeScanner()
let codes = try await barcode.detectQRCodes(in: qrImage)
```

## Compliance & Privacy

- All processing on-device (no cloud transmission)
- Neural Engine support for optimal privacy
- Configurable compute units for privacy/performance trade-off
- VCARD and URL extraction from QR codes only when needed
- No data persistence in ML services

## Extensibility

- **MLModelWrapper Protocol**: Easy addition of new model types
- **AsyncStream Support**: Pluggable frame sources
- **Confidence Filter**: Customizable filtering strategies
- **Model Registry**: Dynamic model loading and registration
- **Configuration Presets**: Easy switching between optimization profiles

## Dependencies

- Foundation
- CoreML
- Vision
- AVFoundation
- CoreImage
- NaturalLanguage
- os.log

## Future Enhancements

- Multi-model ensemble inference
- Transfer learning capabilities
- On-device model fine-tuning
- Custom model format support
- Advanced caching strategies
- Federated learning support
- Model quantization utilities
