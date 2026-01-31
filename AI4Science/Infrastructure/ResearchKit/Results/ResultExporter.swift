import Foundation

/// Exports processed results in standard formats
enum ResultExporter {
    // MARK: - Public Methods

    /// Export results in specified format
    static func export(_ result: ProcessedResult, format: ResultExportFormat) throws -> Data {
        switch format {
        case .json:
            return try exportJSON(result)
        case .csv:
            return try exportCSV(result)
        case .xml:
            return try exportXML(result)
        case .jsonld:
            return try exportJSONLD(result)
        }
    }

    // MARK: - Private Methods

    private static func exportJSON(_ result: ProcessedResult) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonResult = JSONResultWrapper(
            taskIdentifier: result.taskIdentifier,
            timestamp: result.timestamp,
            duration: result.duration,
            isComplete: result.isComplete,
            errorCount: result.errors.count
        )

        return try encoder.encode(jsonResult)
    }

    private static func exportCSV(_ result: ProcessedResult) throws -> Data {
        var csvContent = "Task ID,Timestamp,Duration (seconds),Complete,Errors\n"

        let line = "\(escape(result.taskIdentifier)),\(result.timestamp.ISO8601Format()),\(Int(result.duration)),\(result.isComplete),\(result.errors.count)\n"
        csvContent += line

        guard let data = csvContent.data(using: .utf8) else {
            throw ResultExporterError.encodingFailed
        }

        return data
    }

    private static func exportXML(_ result: ProcessedResult) throws -> Data {
        var xmlContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xmlContent += "<taskResult>\n"
        xmlContent += "  <taskIdentifier>\(escape(result.taskIdentifier))</taskIdentifier>\n"
        xmlContent += "  <timestamp>\(result.timestamp.ISO8601Format())</timestamp>\n"
        xmlContent += "  <duration>\(result.duration)</duration>\n"
        xmlContent += "  <isComplete>\(result.isComplete)</isComplete>\n"
        xmlContent += "  <errors>\n"

        for error in result.errors {
            xmlContent += "    <error>\n"
            xmlContent += "      <stepId>\(escape(error.stepId))</stepId>\n"
            xmlContent += "      <message>\(escape(error.error))</message>\n"
            xmlContent += "    </error>\n"
        }

        xmlContent += "  </errors>\n"
        xmlContent += "</taskResult>\n"

        guard let data = xmlContent.data(using: .utf8) else {
            throw ResultExporterError.encodingFailed
        }

        return data
    }

    private static func exportJSONLD(_ result: ProcessedResult) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let jsonldResult: [String: Any] = [
            "@context": [
                "@vocab": "http://schema.org/",
                "ai4science": "http://ai4science.org/ontology/"
            ],
            "@type": "ResearchTask",
            "identifier": result.taskIdentifier,
            "timestamp": result.timestamp.ISO8601Format(),
            "duration": result.duration,
            "isComplete": result.isComplete,
            "errorCount": result.errors.count
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonldResult, options: [.prettyPrinted, .sortedKeys]) else {
            throw ResultExporterError.encodingFailed
        }

        return jsonData
    }

    private static func escape(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

// MARK: - Export Formats
enum ResultExportFormat: String, Sendable {
    case json = "application/json"
    case csv = "text/csv"
    case xml = "application/xml"
    case jsonld = "application/ld+json"

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .xml: return "xml"
        case .jsonld: return "jsonld"
        }
    }

    var mimeType: String {
        return self.rawValue
    }
}

// MARK: - Models
struct JSONResultWrapper: Codable {
    let taskIdentifier: String
    let timestamp: Date
    let duration: TimeInterval
    let isComplete: Bool
    let errorCount: Int

    enum CodingKeys: String, CodingKey {
        case taskIdentifier = "task_id"
        case timestamp
        case duration
        case isComplete = "is_complete"
        case errorCount = "error_count"
    }
}

// MARK: - Error Types
enum ResultExporterError: LocalizedError {
    case unsupportedFormat(String)
    case encodingFailed
    case invalidData

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "Unsupported export format: \(format)"
        case .encodingFailed:
            return "Failed to encode result data"
        case .invalidData:
            return "Result data is invalid"
        }
    }
}
