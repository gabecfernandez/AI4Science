import Foundation
import ResearchKit

/// Task for guided sample collection workflow
struct SampleCollectionTask: Sendable {
    // MARK: - Properties
    let identifier = "sampleCollectionTask"
    let title = "Sample Collection"
    let sampleType: String

    // MARK: - Initialization
    init(sampleType: String = "general") {
        self.sampleType = sampleType
    }

    // MARK: - Methods

    /// Build the sample collection task
    func buildTask() throws -> ORKTask {
        var steps: [ORKStep] = []

        // Welcome step
        let welcomeStep = InstructionStepFactory.createInstructionStep(
            identifier: "sampleCollection_welcome",
            title: "Sample Collection",
            text: "Please follow these instructions carefully to collect a quality sample for analysis."
        )
        steps.append(welcomeStep)

        // Safety information
        let safetyStep = ORKInstructionStep(identifier: "sampleCollection_safety")
        safetyStep.title = "Safety Information"
        safetyStep.text = """
            Before you begin:
            - Wash your hands thoroughly
            - Use the sterile collection kit provided
            - Avoid touching the inside of containers
            - Work in a clean, well-lit area
            - If you feel uncomfortable, stop and contact support
            """
        safetyStep.image = UIImage(systemName: "hand.raised.fill")
        steps.append(safetyStep)

        // Sample type selection
        let sampleTypeStep = ORKQuestionStep(
            identifier: "sampleType",
            title: "Sample Type",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .singleChoice,
                textChoices: [
                    ORKTextChoice(text: "Saliva", value: "saliva"),
                    ORKTextChoice(text: "Soil", value: "soil"),
                    ORKTextChoice(text: "Water", value: "water"),
                    ORKTextChoice(text: "Plant Material", value: "plant"),
                    ORKTextChoice(text: "Swab", value: "swab"),
                    ORKTextChoice(text: "Other", value: "other")
                ]
            )
        )
        sampleTypeStep.text = "Which type of sample are you collecting?"
        steps.append(sampleTypeStep)

        // Type-specific instructions
        let instructionsStep = createTypeSpecificInstructionsStep()
        steps.append(instructionsStep)

        // Collection process
        let collectionStep = ORKInstructionStep(identifier: "sampleCollection_process")
        collectionStep.title = "Collection Process"
        collectionStep.text = """
            Follow these steps:
            1. Open the sterile collection kit
            2. Collect your sample according to type-specific instructions
            3. Fill the container to the marked line
            4. Secure the cap tightly
            5. Label with the date and time
            6. Photograph the sample (if instructed)
            """
        collectionStep.image = UIImage(systemName: "doc.text.fill")
        steps.append(collectionStep)

        // Confirmation of collection
        let confirmationStep = ORKQuestionStep(
            identifier: "collectionConfirmation",
            title: "Sample Collection Confirmation",
            answer: ORKAnswerFormat.booleanAnswerFormat()
        )
        confirmationStep.text = "Have you successfully collected the sample?"
        steps.append(confirmationStep)

        // Sample details form
        let detailsStep = ORKFormStep(identifier: "sampleDetails", title: "Sample Information", text: "Provide details about your sample")
        let dateAnswerFormat = ORKDateAnswerFormat(style: .dateAndTime)
        detailsStep.formItems = [
            ORKFormItem(
                identifier: "collectionDate",
                text: "Collection Date and Time",
                answerFormat: dateAnswerFormat,
                optional: false
            ),
            ORKFormItem(
                identifier: "collectionLocation",
                text: "Collection Location",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 100),
                optional: false
            ),
            ORKFormItem(
                identifier: "sampleVolume",
                text: "Sample Volume (mL)",
                answerFormat: ORKAnswerFormat.decimalAnswerFormat(withUnit: "mL"),
                optional: true
            ),
            ORKFormItem(
                identifier: "storageCondition",
                text: "Storage Condition",
                answerFormat: ORKAnswerFormat.choiceAnswerFormat(
                    with: .singleChoice,
                    textChoices: [
                        ORKTextChoice(text: "Room Temperature", value: "room"),
                        ORKTextChoice(text: "Refrigerated (4°C)", value: "refrigerated"),
                        ORKTextChoice(text: "Frozen (-20°C)", value: "frozen")
                    ]
                ),
                optional: false
            ),
            ORKFormItem(
                identifier: "additionalNotes",
                text: "Additional Notes",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 500),
                optional: true
            )
        ]
        steps.append(detailsStep)

        // Photo documentation
        let photoStep = ORKInstructionStep(identifier: "sampleCollection_photo")
        photoStep.title = "Photo Documentation (Optional)"
        photoStep.text = "Take a photo of your sample for documentation purposes. Make sure the sample container is clearly visible and labeled."
        photoStep.image = UIImage(systemName: "camera.fill")
        steps.append(photoStep)

        // Quality assessment
        let qualityStep = ORKQuestionStep(
            identifier: "sampleQuality",
            title: "Sample Quality Self-Assessment",
            answer: ORKAnswerFormat.scale(
                withMaximumValue: 5,
                minimumValue: 1,
                defaultValue: 3,
                step: 1,
                vertical: false,
                maximumValueDescription: "Excellent",
                minimumValueDescription: "Poor"
            )
        )
        qualityStep.text = "How would you rate the quality of your sample?"
        steps.append(qualityStep)

        // Storage and preparation
        let storageStep = ORKInstructionStep(identifier: "sampleCollection_storage")
        storageStep.title = "Storage and Preparation for Shipping"
        storageStep.text = """
            Please:
            1. Store the sample in the appropriate location based on your selection
            2. Keep the sample label visible
            3. Do not open or disturb the sample
            4. Prepare for shipping according to provided instructions
            5. Ship within the specified timeframe
            """
        storageStep.image = UIImage(systemName: "shippingbox.fill")
        steps.append(storageStep)

        // Shipping information
        let shippingStep = ORKFormStep(identifier: "shippingInfo", title: "Shipping Information", text: "Complete your shipping details")
        shippingStep.formItems = [
            ORKFormItem(
                identifier: "shippingAddress",
                text: "Shipping Address (will be provided)",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 200),
                optional: false
            ),
            ORKFormItem(
                identifier: "trackingNumber",
                text: "Tracking Number (after shipping)",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 50),
                optional: true
            ),
            ORKFormItem(
                identifier: "shippingDate",
                text: "Planned Shipping Date",
                answerFormat: ORKDateAnswerFormat(style: .dateAndTime),
                optional: false
            )
        ]
        steps.append(shippingStep)

        // Issues and concerns
        let issuesStep = ORKQuestionStep(
            identifier: "collectionIssues",
            title: "Issues or Concerns",
            answer: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 500)
        )
        issuesStep.text = "Did you encounter any issues during sample collection? (Optional)"
        issuesStep.isOptional = true
        steps.append(issuesStep)

        // Review
        let reviewStep = ReviewStepFactory.createReviewStep(
            identifier: "sampleCollection_review",
            title: "Review Sample Collection",
            text: "Please review all information before completing"
        )
        steps.append(reviewStep)

        // Completion
        let completionStep = CompletionStepFactory.createCompletionStep(
            identifier: "sampleCollection_completion",
            title: "Sample Collection Complete",
            text: "Thank you for collecting your sample. Your contribution is valuable to our research. You will receive further instructions for sample submission."
        )
        steps.append(completionStep)

        return ORKOrderedTask(identifier: identifier, steps: steps)
    }

    // MARK: - Private Methods

    private func createTypeSpecificInstructionsStep() -> ORKStep {
        let step = ORKInstructionStep(identifier: "typeSpecificInstructions")
        step.title = "Type-Specific Instructions"

        switch sampleType {
        case "saliva":
            step.text = """
                Saliva Collection Instructions:
                1. Avoid eating, drinking, or smoking for 30 minutes before collection
                2. Rinse your mouth with water
                3. Spit directly into the provided collection tube
                4. Fill to the marked line
                5. Secure the cap immediately
                """

        case "soil":
            step.text = """
                Soil Collection Instructions:
                1. Choose a representative location at least 5 meters from obvious contamination
                2. Remove surface litter
                3. Dig a small hole approximately 10-15 cm deep
                4. Collect soil from the side of the hole
                5. Fill the container to capacity
                """

        case "water":
            step.text = """
                Water Collection Instructions:
                1. Use only sterile collection containers provided
                2. Submerge container 15-30 cm below the surface
                3. Allow water to flow into the container for 30 seconds
                4. Cap immediately after collection
                5. Keep sample cool and process within 24 hours
                """

        case "plant":
            step.text = """
                Plant Material Collection Instructions:
                1. Select healthy, disease-free plant parts
                2. Cut or pinch leaves/stems cleanly
                3. Place immediately in the sterile envelope provided
                4. Seal the envelope properly
                5. Include date, location, and species information
                """

        case "swab":
            step.text = """
                Swab Collection Instructions:
                1. Unwrap the sterile swab carefully
                2. Swab the specified area using firm, circular motions
                3. Avoid touching the swab tip with your hands
                4. Place immediately in the collection tube
                5. Break the swab stick if instructed
                """

        default:
            step.text = """
                Sample Collection Instructions:
                Follow the specific guidelines provided for your sample type.
                Contact support if you have any questions.
                """
        }

        return step
    }
}

// MARK: - Models
struct SampleCollectionResponse: Codable, Sendable {
    let sampleType: String
    let collectionDate: Date
    let collectionLocation: String
    let sampleVolume: Double?
    let storageCondition: String
    let qualityRating: Int
    let additionalNotes: String?
    let shippingDate: Date
    let issues: String?
}
