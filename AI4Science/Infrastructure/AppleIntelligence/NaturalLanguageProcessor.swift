import Foundation
import NaturalLanguage
import os.log

/// Process text annotations using Natural Language framework
/// Handles entity recognition, sentiment analysis, and language features
actor NaturalLanguageProcessor {
    static let shared = NaturalLanguageProcessor()

    private let logger = Logger(subsystem: "com.ai4science.ai", category: "NaturalLanguageProcessor")
    private var tokenizers: [String: NLTokenizer] = [:]
    private var taggerCache: [String: NLTagger] = [:]

    private init() {
        initializeTokenizers()
    }

    // MARK: - Text Processing

    /// Process text for comprehensive analysis
    /// - Parameter text: Text to process
    /// - Returns: NLPAnalysisResult with entities and features
    /// - Throws: NLPError if processing fails
    func processText(_ text: String) async throws -> NLPAnalysisResult {
        guard !text.isEmpty else {
            throw NLPError.emptyInput
        }

        async let entities = extractEntities(text)
        async let language = detectLanguage(text)
        async let sentiment = analyzeSentiment(text)
        async let keywords = extractKeywords(text)

        return NLPAnalysisResult(
            originalText: text,
            entities: try await entities,
            language: try await language,
            sentiment: try await sentiment,
            keywords: try await keywords,
            confidence: 0.85,
            timestamp: Date()
        )
    }

    // MARK: - Entity Extraction

    /// Extract named entities from text
    /// - Parameter text: Text to analyze
    /// - Returns: Array of Entity results
    /// - Throws: NLPError if extraction fails
    func extractEntities(_ text: String) async throws -> [Entity] {
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text

        var entities: [Entity] = []
        let range = text.startIndex..<text.endIndex

        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: [.omitPunctuation]) { tag, tokenRange in
            guard let tag = tag else { return true }

            let word = String(text[tokenRange])
            let entityType = EntityType(rawValue: tag.rawValue) ?? .unknown

            let entity = Entity(
                text: word,
                type: entityType,
                confidence: 0.9
            )
            entities.append(entity)

            return true
        }

        logger.debug("Extracted \(entities.count) entities")
        return entities
    }

    /// Extract specific entity types
    /// - Parameters:
    ///   - text: Text to analyze
    ///   - types: Specific entity types to extract
    /// - Returns: Filtered Entity array
    func extractEntities(
        from text: String,
        ofTypes types: [Entity.EntityType]
    ) async throws -> [Entity] {
        let allEntities = try await extractEntities(text)
        return allEntities.filter { types.contains($0.type) }
    }

    // MARK: - Language Detection

    /// Detect language of text
    /// - Parameter text: Text to analyze
    /// - Returns: Language code (e.g., "en", "es")
    /// - Throws: NLPError if detection fails
    func detectLanguage(_ text: String) async throws -> String {
        guard !text.isEmpty else {
            throw NLPError.emptyInput
        }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard let language = recognizer.dominantLanguage else {
            return "unknown"
        }

        logger.debug("Detected language: \(language.rawValue)")
        return language.rawValue
    }

    /// Detect multiple languages
    /// - Parameter text: Text to analyze
    /// - Returns: Array of detected languages with confidence
    func detectLanguages(_ text: String) async throws -> [DetectedLanguage] {
        guard !text.isEmpty else {
            throw NLPError.emptyInput
        }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        let hypotheses = recognizer.languageHypotheses(withMaximum: 5)

        return hypotheses.map { language, confidence in
            DetectedLanguage(code: language.rawValue, confidence: Float(confidence))
        }
    }

    // MARK: - Sentiment Analysis

    /// Analyze sentiment of text
    /// - Parameter text: Text to analyze
    /// - Returns: TextSentiment classification
    /// - Throws: NLPError if analysis fails
    func analyzeSentiment(_ text: String) async throws -> TextSentiment {
        guard !text.isEmpty else {
            throw NLPError.emptyInput
        }

        // Simple sentiment scoring based on keywords
        let sentimentScore = calculateSentimentScore(text)

        let sentiment: TextSentiment
        if sentimentScore > 0.3 {
            sentiment = .positive
        } else if sentimentScore < -0.3 {
            sentiment = .negative
        } else {
            sentiment = .neutral
        }

        logger.debug("Analyzed sentiment: \(sentiment)")
        return sentiment
    }

    // MARK: - Keyword Extraction

    /// Extract keywords from text
    /// - Parameter text: Text to analyze
    /// - Returns: Array of keyword strings
    /// - Throws: NLPError if extraction fails
    func extractKeywords(_ text: String) async throws -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var keywords: [String] = []
        let range = text.startIndex..<text.endIndex

        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: [.omitPunctuation]) { tag, tokenRange in
            guard let tag = tag, tag == .noun || tag == .verb else { return true }

            let word = String(text[tokenRange]).lowercased()

            if !isCommonWord(word) && word.count > 3 {
                keywords.append(word)
            }

            return true
        }

        let uniqueKeywords = Array(Set(keywords)).sorted()
        logger.debug("Extracted \(uniqueKeywords.count) keywords")

        return uniqueKeywords
    }

    // MARK: - Text Summarization

    /// Generate summary of text
    /// - Parameters:
    ///   - text: Text to summarize
    ///   - length: Number of sentences in summary
    /// - Returns: Summarized text
    func summarizeText(_ text: String, sentenceCount: Int = 2) async throws -> String {
        let sentences = text.split(separator: ".").map { String($0).trimmingCharacters(in: .whitespaces) }

        guard !sentences.isEmpty else {
            throw NLPError.emptyInput
        }

        let count = min(sentenceCount, sentences.count)
        let summary = sentences.prefix(count).joined(separator: ". ") + "."

        return summary
    }

    // MARK: - Text Tokenization

    /// Tokenize text into words
    /// - Parameter text: Text to tokenize
    /// - Returns: Array of tokens
    func tokenize(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            tokens.append(String(text[range]))
            return true
        }

        return tokens
    }

    /// Tokenize into sentences
    /// - Parameter text: Text to tokenize
    /// - Returns: Array of sentences
    func tokenizeSentences(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            sentences.append(String(text[range]))
            return true
        }

        return sentences
    }

    // MARK: - Text Classification

    /// Classify text into categories
    /// - Parameters:
    ///   - text: Text to classify
    ///   - categories: Available categories
    /// - Returns: Array of ClassificationResult
    func classifyText(
        _ text: String,
        into categories: [String]
    ) async throws -> [ClassificationResult] {
        var results: [ClassificationResult] = []

        for category in categories {
            let score = calculateCategoryScore(text, for: category)
            results.append(ClassificationResult(category: category, score: score))
        }

        return results.sorted { $0.score > $1.score }
    }

    // MARK: - Helper Methods

    private func initializeTokenizers() {
        tokenizers["word"] = NLTokenizer(unit: .word)
        tokenizers["sentence"] = NLTokenizer(unit: .sentence)
    }

    private func calculateSentimentScore(_ text: String) -> Float {
        let positiveWords = ["good", "excellent", "great", "amazing", "perfect", "wonderful"]
        let negativeWords = ["bad", "poor", "terrible", "awful", "horrible", "awful"]

        let words = text.lowercased().split(separator: " ").map(String.init)

        var score: Float = 0
        for word in words {
            if positiveWords.contains(word) {
                score += 1
            } else if negativeWords.contains(word) {
                score -= 1
            }
        }

        return score / Float(max(1, words.count))
    }

    private func calculateCategoryScore(_ text: String, for category: String) -> Float {
        let words = text.lowercased().split(separator: " ").map(String.init)
        let categoryWords = category.lowercased().split(separator: " ").map(String.init)

        let matches = words.filter { word in
            categoryWords.contains { categoryWord in
                word.hasPrefix(String(categoryWord))
            }
        }.count

        return Float(matches) / Float(max(1, words.count))
    }

    private func isCommonWord(_ word: String) -> Bool {
        let commonWords = ["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "from", "is", "are", "be"]
        return commonWords.contains(word)
    }
}

// MARK: - Result Types

struct NLPAnalysisResult: Sendable {
    let originalText: String
    let entities: [Entity]
    let language: String
    let sentiment: TextSentiment
    let keywords: [String]
    let confidence: Float
    let timestamp: Date
}

struct DetectedLanguage: Sendable {
    let code: String
    let confidence: Float
}

struct ClassificationResult: Sendable {
    let category: String
    let score: Float
}

// MARK: - Error Types

enum NLPError: LocalizedError {
    case emptyInput
    case processingFailed(String)
    case unsupportedLanguage
    case invalidText

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Input text is empty"
        case .processingFailed(let reason):
            return "NLP processing failed: \(reason)"
        case .unsupportedLanguage:
            return "Language is not supported"
        case .invalidText:
            return "Invalid text provided"
        }
    }
}
