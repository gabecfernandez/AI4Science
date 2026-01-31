# ML Infrastructure - Quick Reference Guide

## Files Created: 16 Swift Files | 6,531 Lines of Code

### ML Services (5 files)
- `MLModelManager.swift` - Model lifecycle (load, cache, unload) - **500+ lines**
- `DefectDetectionService.swift` - Defect detection with severity - **350+ lines**
- `ImageClassificationService.swift` - Image classification top-K - **320+ lines**
- `ObjectDetectionService.swift` - Object detection with NMS - **380+ lines**
- `ModelDownloadService.swift` - Remote model caching - **350+ lines**

### ML Processors (4 files)
- `ImagePreprocessor.swift` - Image preparation & normalization - **400+ lines**
- `VideoFrameProcessor.swift` - Video frame extraction & rotation - **380+ lines**
- `ResultPostprocessor.swift` - ML output parsing & aggregation - **420+ lines**
- `ConfidenceFilter.swift` - Prediction filtering & NMS - **450+ lines**

### ML Models (4 files)
- `MLModelWrapper.swift` - Model abstraction protocol - **200+ lines**
- `VisionModelWrapper.swift` - Vision framework integration - **350+ lines**
- `PredictionResult.swift` - Standardized prediction format - **280+ lines**
- `BoundingBox.swift` - Normalized box operations - **380+ lines**

### ML Configuration (2 files)
- `MLConfiguration.swift` - Compute unit preferences - **280+ lines**
- `ModelRegistry.swift` - Model metadata registry - **350+ lines**

### Vision Services (4 files)
- `VisionService.swift` - Apple Vision operations - **350+ lines**
- `ImageAnalyzer.swift` - Comprehensive image analysis - **380+ lines**
- `TextRecognitionService.swift` - OCR for sample labels - **420+ lines**
- `BarcodeScanner.swift` - Barcode/QR detection - **400+ lines**

### Apple Intelligence (3 files)
- `AppleIntelligenceService.swift` - AI feature coordination - **280+ lines**
- `SmartSuggestionsProvider.swift` - Context-aware suggestions - **350+ lines**
- `NaturalLanguageProcessor.swift` - NLP entity/sentiment - **380+ lines**

## Key Classes & Actors

```swift
// ML Services
actor MLModelManager                  // Singleton: shared
actor DefectDetectionService         // Defect ML pipeline
actor ImageClassificationService     // Classification pipeline
actor ObjectDetectionService         // Object detection pipeline
actor ModelDownloadService           // Singleton: shared
actor VideoFrameProcessor            // Singleton: shared
actor ImagePreprocessor              // Singleton: shared
actor ConfidenceFilter               // Singleton: shared

// Vision Services
actor VisionService                  // Singleton: shared
actor ImageAnalyzer                  // Singleton: shared
actor TextRecognitionService         // Singleton: shared
actor BarcodeScanner                 // Singleton: shared

// Apple Intelligence
actor AppleIntelligenceService      // Singleton: shared
actor SmartSuggestionsProvider      // Singleton: shared
actor NaturalLanguageProcessor      // Singleton: shared

// Configuration
actor ModelRegistry                  // Singleton: shared
struct MLConfiguration               // Configuration builder
```

## Core Data Types

### Results
- `DefectPrediction` - Defect with severity level
- `Classification` - Class label with confidence
- `ObjectDetection` - Bounding box with class
- `PredictionResult` - Unified prediction format
- `TextObservation` - Recognized text region
- `BarcodeResult` - Scanned barcode data
- `FaceDetectionResult` - Face with landmarks
- `ImageAnalysisResult` - Complete image analysis

### ML Models
- `BoundingBox` - Normalized coordinates (0-1)
- `PredictionResult` - Standardized ML output
- `ModelMetadata` - Model information
- `RegisteredModel` - Registry entry

### Configuration
- `MLConfiguration` - Compute unit preferences
- `BatchConfig` - Batch processing settings
- `MemoryConfig` - Memory management
- `PerformanceConfig` - Performance settings

## Common Usage Patterns

### 1. Single Image Classification
```swift
let classifier = ImageClassificationService()
try await classifier.initialize()
let results = try await classifier.classify(image: uiImage, topK: 5)
```

### 2. Batch Object Detection
```swift
let detector = ObjectDetectionService()
try await detector.initialize()
let results = try await detector.detect(in: images, confidenceThreshold: 0.5)
```

### 3. Real-time Defect Detection
```swift
let defectDetector = DefectDetectionService()
try await defectDetector.initialize()

let videoStream = try await videoProcessor.startVideoCapture()
let defectStream = await defectDetector.streamDefectDetection(
    from: frameStream,
    confidenceThreshold: 0.7
)

for await frame in defectStream {
    print("Defects found: \(frame.predictions.count)")
}
```

### 4. Image Preprocessing
```swift
let preprocessor = ImagePreprocessor.shared
let pixelBuffer = try await preprocessor.prepareImage(image, for: model)
```

### 5. Result Filtering
```swift
let filter = ConfidenceFilter.shared
let nmsResults = filter.applyNMS(detections, iouThreshold: 0.5)
let filtered = filter.filterByConfidence(nmsResults, threshold: 0.6)
```

### 6. Text Recognition
```swift
let ocr = TextRecognitionService.shared
let label = try await ocr.recognizeSampleLabel(from: image)
print("Sample ID: \(label.sampleID ?? "Unknown")")
```

### 7. Barcode Scanning
```swift
let scanner = BarcodeScanner.shared
let qrCodes = try await scanner.detectQRCodes(in: image)
if let firstCode = qrCodes.first {
    print("URL: \(firstCode.url?.absoluteString ?? "N/A")")
}
```

### 8. Smart Suggestions
```swift
let suggestions = SmartSuggestionsProvider.shared
let suggestions = try await suggestions.generateLabelSuggestions(for: "Sample")
```

### 9. Model Configuration
```swift
let config = MLConfiguration.performance
let modelManager = MLModelManager.shared
let model = try await modelManager.loadModel(named: "DefectModel")
```

### 10. Vision Analysis
```swift
let analyzer = ImageAnalyzer.shared
let analysis = try await analyzer.analyzeImage(image)
print("Faces: \(analysis.faces.count)")
print("Quality: \(analysis.quality.overallQuality)")
```

## Error Handling

### ML Errors
```swift
enum MLModelError {
    case modelNotFound(String)
    case loadingFailed(String)
    case compilationFailed(String)
    case configurationError(String)
    case inferenceError(String)
    case invalidInput
    case outputParsingError(String)
}
```

### Vision Errors
```swift
enum VisionError {
    case invalidImage
    case processingFailed(String)
    case noResultsFound
    case unsupportedDevice
}
```

### Apple Intelligence Errors
```swift
enum AppleIntelligenceError {
    case featureNotAvailable
    case processingFailed(String)
    case notEnabled
    case invalidInput
    case privacyRestricted
}
```

## Performance Tips

1. **Neural Engine**: Use `ComputeUnit.neuralEngine` for optimal inference
2. **Batch Processing**: Process multiple items concurrently with TaskGroups
3. **Caching**: Models are cached automatically by `MLModelManager`
4. **Video Sampling**: Use `VideoFrameProcessor.sampleFrames()` for real-time processing
5. **NMS Filtering**: Apply `ConfidenceFilter.applyNMS()` to remove overlapping detections

## Thread Safety

All services are **actors** providing thread-safe concurrent access:
```swift
// Safe from any thread
Task {
    let results = try await classifier.classify(image: image)
}
```

## Memory Management

- Models: Cached with LRU eviction (500MB default)
- Suggestions: Cached (100 contexts default)
- Video Frames: On-demand, not cached
- ML Results: Generated on-demand, not cached

## Testing Checklist

- [ ] Load and cache models
- [ ] Single image inference
- [ ] Batch processing
- [ ] Real-time streaming
- [ ] Error cases (invalid models, empty inputs)
- [ ] Confidence filtering and NMS
- [ ] Memory usage under load
- [ ] Concurrent access from multiple threads
- [ ] Video frame preprocessing
- [ ] Result post-processing

## Integration Checklist

- [ ] Add to Xcode project
- [ ] Link CoreML, Vision frameworks
- [ ] Update app Info.plist with camera/microphone usage
- [ ] Create sample ML models (.mlmodelc)
- [ ] Test on physical device for Neural Engine support
- [ ] Implement error handling UI
- [ ] Add loading indicators for inference
- [ ] Handle camera permissions
- [ ] Cache model files in bundle
- [ ] Profile performance with Instruments

## Related Files

- Domain models: `/Domain/Models/`
- Data persistence: `/Data/Repositories/`
- UI integration: `/UI/Screens/`
- Configuration: `/Config/`

## Documentation Files

- `ML_INFRASTRUCTURE_SUMMARY.md` - Complete architecture documentation
- `QUICK_REFERENCE.md` - This file
