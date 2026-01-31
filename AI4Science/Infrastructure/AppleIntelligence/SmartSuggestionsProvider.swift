import Foundation
import os.log

/// Provides context-aware smart suggestions using Apple Intelligence
/// Generates intelligent recommendations based on user context
actor SmartSuggestionsProvider {
    static let shared = SmartSuggestionsProvider()

    private let logger = Logger(subsystem: "com.ai4science.ai", category: "SmartSuggestionsProvider")
    private var suggestionCache: [String: [String]] = [:]
    private let maxCacheSize = 100

    private init() {}

    // MARK: - Suggestion Generation

    /// Generate smart suggestions for a given context
    /// - Parameter context: Context string for generating suggestions
    /// - Returns: Array of suggested strings
    /// - Throws: AppleIntelligenceError if generation fails
    func generateSuggestions(for context: String) async throws -> [String] {
        // Check cache first
        if let cached = suggestionCache[context] {
            logger.debug("Using cached suggestions for context")
            return cached
        }

        let suggestions = try await generateSuggestionsInternal(for: context)

        // Cache the result
        await cacheSuggestions(suggestions, for: context)

        return suggestions
    }

    /// Generate multiple suggestion sets
    /// - Parameter contexts: Array of context strings
    /// - Returns: Dictionary mapping context to suggestions
    /// - Throws: AppleIntelligenceError if generation fails
    func generateSuggestions(for contexts: [String]) async throws -> [String: [String]] {
        var results: [String: [String]] = [:]

        for context in contexts {
            let suggestions = try await generateSuggestions(for: context)
            results[context] = suggestions
        }

        return results
    }

    // MARK: - Context-Aware Suggestions

    /// Generate suggestions for sample labeling
    /// - Parameter partialLabel: Partial label text
    /// - Returns: Array of label suggestions
    func generateLabelSuggestions(for partialLabel: String) async throws -> [String] {
        let context = "sample_label: \(partialLabel)"
        return try await generateSuggestions(for: context)
    }

    /// Generate suggestions for sample descriptions
    /// - Parameter partialDescription: Partial description text
    /// - Returns: Array of description suggestions
    func generateDescriptionSuggestions(for partialDescription: String) async throws -> [String] {
        let context = "sample_description: \(partialDescription)"
        return try await generateSuggestions(for: context)
    }

    /// Generate suggestions for analysis notes
    /// - Parameter partialNote: Partial note text
    /// - Returns: Array of note suggestions
    func generateNoteSuggestions(for partialNote: String) async throws -> [String] {
        let context = "analysis_note: \(partialNote)"
        return try await generateSuggestions(for: context)
    }

    /// Generate follow-up suggestions
    /// - Parameter context: Previous context or conversation
    /// - Returns: Array of follow-up suggestions
    func generateFollowUpSuggestions(for context: String) async throws -> [String] {
        let suggestions = try await generateSuggestions(for: context)
        return suggestions.prefix(3).map { $0 + "..." }
    }

    // MARK: - Ranking & Filtering

    /// Rank suggestions by relevance
    /// - Parameters:
    ///   - suggestions: Array of suggestions to rank
    ///   - context: Context for relevance scoring
    /// - Returns: Sorted suggestions by relevance
    func rankSuggestions(
        _ suggestions: [String],
        for context: String
    ) -> [String] {
        return suggestions.sorted { suggestion1, suggestion2 in
            let score1 = calculateRelevanceScore(suggestion1, for: context)
            let score2 = calculateRelevanceScore(suggestion2, for: context)
            return score1 > score2
        }
    }

    /// Filter suggestions by criteria
    /// - Parameters:
    ///   - suggestions: Array of suggestions to filter
    ///   - minLength: Minimum character length
    ///   - maxLength: Maximum character length
    /// - Returns: Filtered suggestions
    func filterSuggestions(
        _ suggestions: [String],
        minLength: Int = 3,
        maxLength: Int = 100
    ) -> [String] {
        return suggestions.filter { suggestion in
            suggestion.count >= minLength && suggestion.count <= maxLength
        }
    }

    /// Filter suggestions by categories
    /// - Parameters:
    ///   - suggestions: Array of suggestions
    ///   - categories: Allowed categories
    /// - Returns: Filtered suggestions
    func filterSuggestions(
        _ suggestions: [String],
        categories: [SuggestionCategory]
    ) -> [String] {
        return suggestions.filter { suggestion in
            categories.contains { category in
                suggestion.lowercased().contains(category.keyword)
            }
        }
    }

    // MARK: - Machine Learning Integration

    /// Get ML model predictions for suggestion ranking
    /// - Parameters:
    ///   - suggestions: Suggestions to score
    ///   - context: User context
    /// - Returns: Array of scored suggestions
    func scoreWithML(
        _ suggestions: [String],
        context: String
    ) async -> [ScoredSuggestion] {
        return suggestions.enumerated().map { index, suggestion in
            ScoredSuggestion(
                text: suggestion,
                score: calculateRelevanceScore(suggestion, for: context),
                rank: index + 1
            )
        }
    }

    // MARK: - Learning from User Feedback

    /// Track user selection for improving suggestions
    /// - Parameters:
    ///   - selectedSuggestion: The suggestion user selected
    ///   - context: Original context
    func trackSelection(
        _ selectedSuggestion: String,
        context: String
    ) async {
        logger.debug("Tracked suggestion selection: \(selectedSuggestion)")
        // In a real implementation, this would update ML models
    }

    /// Track rejected suggestions
    /// - Parameters:
    ///   - rejectedSuggestion: Suggestion user rejected
    ///   - context: Original context
    func trackRejection(
        _ rejectedSuggestion: String,
        context: String
    ) async {
        logger.debug("Tracked suggestion rejection: \(rejectedSuggestion)")
        // In a real implementation, this would update ML models
    }

    // MARK: - Private Methods

    private func generateSuggestionsInternal(for context: String) async throws -> [String] {
        // Simulate suggestion generation
        // In production, this would use CoreML or on-device LLMs
        let suggestions = generateBasedOnContext(context)
        return Array(suggestions.prefix(5))
    }

    private func generateBasedOnContext(_ context: String) -> [String] {
        let lowercased = context.lowercased()

        if lowercased.contains("sample_label") {
            return [
                "Sample ID: S-",
                "Date: ",
                "Material: ",
                "Batch: ",
                "Grade: "
            ]
        } else if lowercased.contains("sample_description") {
            return [
                "This sample contains",
                "Visual inspection shows",
                "Dimensions: ",
                "Weight: ",
                "Composition: "
            ]
        } else if lowercased.contains("analysis_note") {
            return [
                "Results indicate",
                "Further testing required",
                "Sample quality is",
                "Notable observations:",
                "Comparison with baseline:"
            ]
        }

        return ["Complete analysis", "Record results", "Generate report"]
    }

    private func calculateRelevanceScore(_ suggestion: String, for context: String) -> Float {
        let contextWords = context.lowercased().split(separator: " ")
        let suggestionWords = suggestion.lowercased().split(separator: " ")

        let matches = suggestionWords.filter { suggestionWord in
            contextWords.contains { contextWord in
                String(contextWord).hasPrefix(String(suggestionWord)) ||
                String(suggestionWord).hasPrefix(String(contextWord))
            }
        }.count

        return Float(matches) / Float(suggestionWords.count)
    }

    private func cacheSuggestions(_ suggestions: [String], for context: String) async {
        // Implement cache eviction if needed
        if suggestionCache.count >= maxCacheSize {
            let oldestKey = suggestionCache.keys.first
            if let oldestKey = oldestKey {
                suggestionCache.removeValue(forKey: oldestKey)
            }
        }

        suggestionCache[context] = suggestions
    }

    // MARK: - Cache Management

    /// Clear suggestion cache
    nonisolated func clearCache() {
        Task {
            await clearCacheInternal()
        }
    }

    private func clearCacheInternal() {
        suggestionCache.removeAll()
        logger.debug("Cleared suggestion cache")
    }

    /// Get cache statistics
    /// - Returns: Information about cache state
    func getCacheStats() -> [String: Any] {
        return [
            "cachedContexts": suggestionCache.count,
            "maxCacheSize": maxCacheSize
        ]
    }
}

// MARK: - Supporting Types

struct ScoredSuggestion: Sendable {
    let text: String
    let score: Float
    let rank: Int

    var confidence: Float {
        score
    }
}

enum SuggestionCategory: String, Sendable {
    case label = "label"
    case description = "description"
    case analysis = "analysis"
    case date = "date"
    case measurement = "measurement"

    var keyword: String {
        rawValue
    }
}
