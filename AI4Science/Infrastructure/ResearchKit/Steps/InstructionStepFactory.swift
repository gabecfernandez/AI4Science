import Foundation
import ResearchKit

/// Factory for creating instruction steps
enum InstructionStepFactory {
    // MARK: - Public Methods

    /// Create a basic instruction step
    static func createInstructionStep(
        identifier: String,
        title: String,
        text: String,
        detailedText: String? = nil,
        image: UIImage? = nil,
        footnote: String? = nil
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = title
        step.text = text
        step.detailedText = detailedText
        step.image = image
        step.footnote = footnote
        return step
    }

    /// Create a visual instruction step with multiple sections
    static func createVisualInstructionStep(
        identifier: String,
        title: String,
        sections: [InstructionSection]
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = title

        var textContent = ""
        for section in sections {
            textContent += "** \(section.title) **\n\(section.content)\n\n"
        }

        step.text = textContent
        step.image = sections.first?.image

        return step
    }

    /// Create a procedure step with image instructions
    static func createProcedureStep(
        identifier: String,
        title: String,
        steps: [ProcedureStep]
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = title

        var procedureText = "Follow these steps:\n\n"
        for (index, procedureStep) in steps.enumerated() {
            procedureText += "\(index + 1). \(procedureStep.title): \(procedureStep.description)\n"
        }

        step.text = procedureText
        step.image = steps.first?.image

        return step
    }

    /// Create a safety information step
    static func createSafetyStep(
        identifier: String,
        title: String = "Safety Information",
        warnings: [SafetyWarning]
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = title

        var safetyText = "Please read the following safety information carefully:\n\n"
        for warning in warnings {
            safetyText += "⚠️ \(warning.level.rawValue.uppercased()): \(warning.message)\n"
            if let mitigation = warning.mitigation {
                safetyText += "   Action: \(mitigation)\n"
            }
            safetyText += "\n"
        }

        step.text = safetyText
        step.image = UIImage(systemName: "exclamationmark.triangle.fill")

        return step
    }

    /// Create a welcome step
    static func createWelcomeStep(
        identifier: String,
        title: String,
        subtitle: String,
        description: String
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = title
        step.text = description
        step.detailedText = subtitle
        step.image = UIImage(systemName: "hand.thumbsup.fill")
        return step
    }

    /// Create an informational step
    static func createInfoStep(
        identifier: String,
        title: String,
        information: [InfoItem]
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = title

        var infoText = ""
        for item in information {
            infoText += "• \(item.label): \(item.value)\n"
        }

        step.text = infoText
        return step
    }
}

// MARK: - Supporting Types
struct InstructionSection: Sendable {
    let title: String
    let content: String
    let image: UIImage?

    init(title: String, content: String, image: UIImage? = nil) {
        self.title = title
        self.content = content
        self.image = image
    }
}

struct ProcedureStep: Sendable {
    let title: String
    let description: String
    let image: UIImage?
    let estimatedDuration: TimeInterval?

    init(
        title: String,
        description: String,
        image: UIImage? = nil,
        estimatedDuration: TimeInterval? = nil
    ) {
        self.title = title
        self.description = description
        self.image = image
        self.estimatedDuration = estimatedDuration
    }
}

struct SafetyWarning: Sendable {
    enum WarningLevel: String, Sendable {
        case caution
        case warning
        case danger
    }

    let level: WarningLevel
    let message: String
    let mitigation: String?

    init(level: WarningLevel, message: String, mitigation: String? = nil) {
        self.level = level
        self.message = message
        self.mitigation = mitigation
    }
}

struct InfoItem: Sendable {
    let label: String
    let value: String

    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}
