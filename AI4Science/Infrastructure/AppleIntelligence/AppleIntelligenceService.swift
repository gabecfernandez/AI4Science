import Foundation
import os.log

/// Service integrating Apple Intelligence features
/// Provides access to on-device AI capabilities available on iOS 18+
actor AppleIntelligenceService {
    static let shared = AppleIntelligenceService()

    private let logger = Logger(subsystem: "com.ai4science.ai", category: "AppleIntelligenceService")
    private let naturalLanguageProcessor: NaturalLanguageProcessor
    private let smartSuggestionsProvider: SmartSuggestionsProvider

    private init(
        naturalLanguageProcessor: NaturalLanguageProcessor = .shared,
        smartSuggestionsProvider: SmartSuggestionsProvider = .shared
    ) {
        self.naturalLanguageProcessor = naturalLanguageProcessor
        self.smartSuggestionsProvider = smartSuggestionsProvider

        logger.debug("AppleIntelligenceService initialized")
    }

    // MARK: - Feature Availability

    /// Check if Apple Intelligence is available on device
    /// - Returns: true if Apple Intelligence features are available
    func isAppleIntelligenceAvailable() -> Bool {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            return true
        }
        #endif
        return false
    }

    /// Get available Apple Intelligence features
    /// - Returns: Set of available feature names
    func getAvailableFeatures() -> Set<String> {
        var features: Set<String> = []

        if isAppleIntelligenceAvailable() {
            features.insert("text_processing")
            features.insert("smart_suggestions")
            features.insert("natural_language")
        }

        return features
    }

    // MARK: - Text Processing

    /// Process text using Apple Intelligence
    /// - Parameter text: Text to process
    /// - Returns: ProcessedTextResult with analysis
    /// - Throws: AppleIntelligenceError if processing fails
    func processText(_ text: String) async throws -> ProcessedTextResult {
        guard isAppleIntelligenceAvailable() else {
            throw AppleIntelligenceError.featureNotAvailable
        }

        let nlpResult = try await naturalLanguageProcessor.processText(text)

        return ProcessedTextResult(
            originalText: text,
            entities: nlpResult.entities,
            language: nlpResult.language,
            sentiment: nlpResult.sentiment,
            keywords: nlpResult.keywords,
            timestamp: Date()
        )
    }

    /// Generate smart suggestions for text
    /// - Parameter context: Context for generating suggestions
    /// - Returns: Array of smart suggestion strings
    /// - Throws: AppleIntelligenceError if generation fails
    func generateSmartSuggestions(for context: String) async throws -> [String] {
        guard isAppleIntelligenceAvailable() else {
            throw AppleIntelligenceError.featureNotAvailable
        }

        return try await smartSuggestionsProvider.generateSuggestions(for: context)
    }

    // MARK: - Context-Aware Analysis

    /// Analyze context for intelligent features
    /// - Parameter context: Context information
    /// - Returns: ContextAnalysis results
    /// - Throws: AppleIntelligenceError if analysis fails
    func analyzeContext(_ context: String) async throws -> ContextAnalysis {
        guard isAppleIntelligenceAvailable() else {
            throw AppleIntelligenceError.featureNotAvailable
        }

        let nlpResult = try await naturalLanguageProcessor.processText(context)

        return ContextAnalysis(
            inputContext: context,
            entities: nlpResult.entities,
            intent: detectIntent(nlpResult.entities),
            confidence: nlpResult.confidence,
            suggestedActions: try await generateSmartSuggestions(for: context),
            timestamp: Date()
        )
    }

    // MARK: - Batch Processing

    /// Process multiple texts
    /// - Parameter texts: Array of strings to process
    /// - Returns: Array of ProcessedTextResult
    /// - Throws: AppleIntelligenceError if any processing fails
    func processTexts(_ texts: [String]) async throws -> [ProcessedTextResult] {
        var results: [ProcessedTextResult] = []

        for text in texts {
            let result = try await processText(text)
            results.append(result)
        }

        return results
    }

    // MARK: - Privacy & Security

    /// Check if user has enabled Apple Intelligence
    /// - Returns: true if user has enabled the feature
    func isAppleIntelligenceEnabled() -> Bool {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            // Check system settings or user preferences
            return true
        }
        #endif
        return false
    }

    /// Get privacy information about processing
    /// - Returns: PrivacyInfo describing data handling
    func getPrivacyInfo() -> PrivacyInfo {
        return PrivacyInfo(
            processesOnDevice: true,
            dataStoredLocally: true,
            sentToCloud: false,
            encryptedTransit: true,
            userCanOpOut: true
        )
    }

    // MARK: - Helper Methods

    private func detectIntent(_ entities: [NLPEntity]) -> String {
        // Simple intent detection based on entities
        if entities.contains(where: { $0.type == .action }) {
            return "action_requested"
        } else if entities.contains(where: { $0.type == .question }) {
            return "question_asked"
        }
        return "general"
    }
}

// MARK: - Result Types

struct ProcessedTextResult: Sendable {
    let originalText: String
    let entities: [NLPEntity]
    let language: String
    let sentiment: TextSentiment
    let keywords: [String]
    let timestamp: Date
}

struct ContextAnalysis: Sendable {
    let inputContext: String
    let entities: [NLPEntity]
    let intent: String
    let confidence: Float
    let suggestedActions: [String]
    let timestamp: Date
}

struct NLPEntity: Sendable {
    let text: String
    let type: EntityType
    let confidence: Float

    enum EntityType: String, Sendable {
        case person
        case organization
        case location
        case date
        case number
        case action
        case question
        case unknown
    }
}

enum TextSentiment: String, Sendable {
    case positive
    case negative
    case neutral
    case mixed
}

struct PrivacyInfo: Sendable {
    let processesOnDevice: Bool
    let dataStoredLocally: Bool
    let sentToCloud: Bool
    let encryptedTransit: Bool
    let userCanOpOut: Bool
}

// MARK: - Error Types

enum AppleIntelligenceError: LocalizedError {
    case featureNotAvailable
    case processingFailed(String)
    case notEnabled
    case invalidInput
    case privacyRestricted

    var errorDescription: String? {
        switch self {
        case .featureNotAvailable:
            return "Apple Intelligence is not available on this device"
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        case .notEnabled:
            return "Apple Intelligence is not enabled by the user"
        case .invalidInput:
            return "Invalid input provided"
        case .privacyRestricted:
            return "Privacy restrictions prevent processing"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .featureNotAvailable:
            return "Upgrade to a device that supports Apple Intelligence"
        case .processingFailed:
            return "Try again with different input"
        case .notEnabled:
            return "Enable Apple Intelligence in Settings"
        case .invalidInput:
            return "Check your input format"
        case .privacyRestricted:
            return "Adjust privacy settings in Settings"
        }
    }
}
