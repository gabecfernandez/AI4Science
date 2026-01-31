import ResearchKit
import Foundation

/// Builds active tasks for sensor-based data collection
final class ActiveTaskBuilder: TaskBuilder {
    // MARK: - Active Task Creation

    static func buildTask(
        withID identifier: String,
        configuration: TaskConfiguration
    ) -> ORKTask? {
        var steps: [ORKStep] = []

        // Add instruction step
        if !configuration.title.isEmpty {
            let instructionStep = createInstructionStep(
                identifier: "\(identifier)_instruction",
                title: configuration.title,
                text: configuration.description
            )
            steps.append(instructionStep)
        }

        // Build active task steps from configuration
        for stepConfig in configuration.steps {
            if let activeStep = buildActiveStep(from: stepConfig) {
                steps.append(activeStep)
            }
        }

        // Add completion step
        steps.append(createCompletionStep(identifier: "\(identifier)_completion"))

        return ORKOrderedTask(identifier: identifier, steps: steps)
    }

    // MARK: - Image Capture Task

    static func buildImageCaptureTask(
        identifier: String,
        title: String,
        description: String,
        maxImages: Int = 1,
        includeGrid: Bool = true
    ) -> ORKTask {
        var steps: [ORKStep] = []

        steps.append(createInstructionStep(
            identifier: "\(identifier)_instruction",
            title: title,
            text: description
        ))

        let captureStep = ImageCaptureStep(identifier: "\(identifier)_capture")
        captureStep.title = "Capture Image"
        captureStep.maxImageCount = maxImages
        captureStep.useGrid = includeGrid
        steps.append(captureStep)

        steps.append(createCompletionStep(identifier: "\(identifier)_completion"))

        return ORKOrderedTask(identifier: identifier, steps: steps)
    }

    // MARK: - Calibration Task

    static func buildCalibrationTask(
        identifier: String,
        title: String,
        description: String
    ) -> ORKTask {
        var steps: [ORKStep] = []

        steps.append(createInstructionStep(
            identifier: "\(identifier)_instruction",
            title: title,
            text: description
        ))

        let calibrationStep = CalibrationStep(identifier: "\(identifier)_calibration")
        calibrationStep.title = "Camera Calibration"
        steps.append(calibrationStep)

        steps.append(createCompletionStep(identifier: "\(identifier)_completion"))

        return ORKOrderedTask(identifier: identifier, steps: steps)
    }

    // MARK: - Annotation Task

    static func buildAnnotationTask(
        identifier: String,
        title: String,
        description: String,
        image: UIImage?
    ) -> ORKTask {
        var steps: [ORKStep] = []

        steps.append(createInstructionStep(
            identifier: "\(identifier)_instruction",
            title: title,
            text: description
        ))

        let annotationStep = AnnotationStep(identifier: "\(identifier)_annotation")
        annotationStep.title = "Annotate Defects"
        annotationStep.image = image
        steps.append(annotationStep)

        steps.append(createCompletionStep(identifier: "\(identifier)_completion"))

        return ORKOrderedTask(identifier: identifier, steps: steps)
    }

    // MARK: - Fitness Check Task

    static func buildFitnessCheckTask(identifier: String) -> ORKTask {
        let walkingTask = ORKOrderedTask.waist(withIdentifier: identifier)
        return walkingTask
    }

    // MARK: - Voice/Audio Task

    static func buildVoiceTask(
        identifier: String,
        duration: TimeInterval = 10
    ) -> ORKTask {
        let voiceTask = ORKOrderedTask.voiceActivity(
            withIdentifier: identifier,
            intendedUseDescription: "Voice activity recording"
        )
        return voiceTask
    }

    // MARK: - Memory Task

    static func buildMemoryTask(identifier: String) -> ORKTask {
        let memoryTask = ORKOrderedTask.alternativeImaT(withIdentifier: identifier)
        return memoryTask
    }

    // MARK: - Timed Walk Task

    static func buildTimedWalkTask(
        identifier: String,
        distanceInMeters: Double = 100
    ) -> ORKTask {
        let timedWalkTask = ORKOrderedTask.timedWalk(
            withIdentifier: identifier,
            intendedUseDescription: "Timed walk assessment",
            distanceFormatterUnit: .meter,
            shouldIncludeAssistiveDeviceForm: true
        )
        return timedWalkTask
    }

    // MARK: - Gait and Balance Task

    static func buildGaitAndBalanceTask(identifier: String) -> ORKTask {
        let gaitTask = ORKOrderedTask.shortWalk(withIdentifier: identifier)
        return gaitTask
    }

    // MARK: - Tower of Hanoi Task

    static func buildTowerOfHanoiTask(identifier: String) -> ORKTask {
        let towerTask = ORKOrderedTask.towerOfHanoi(withIdentifier: identifier)
        return towerTask
    }

    // MARK: - Reaction Time Task

    static func buildReactionTimeTask(identifier: String) -> ORKTask {
        let reactionTask = ORKOrderedTask.reactionTime(withIdentifier: identifier)
        return reactionTask
    }

    // MARK: - Range of Motion Task

    static func buildRangeOfMotionTask(
        identifier: String,
        limbOption: ORKRangeOfMotionLimbOption = .shoulder
    ) -> ORKTask {
        let rangeTask = ORKOrderedTask.rangeOfMotion(
            withIdentifier: identifier,
            limbOption: limbOption
        )
        return rangeTask
    }

    // MARK: - Hologram Frenzy Task (Pattern Recognition)

    static func buildPatternRecognitionTask(identifier: String) -> ORKTask {
        let patternTask = ORKOrderedTask.hologramFrenzy(withIdentifier: identifier)
        return patternTask
    }

    // MARK: - Private Helpers

    private static func buildActiveStep(from configuration: StepConfiguration) -> ORKStep? {
        switch configuration.type {
        case .instruction:
            return createInstructionStep(
                identifier: configuration.identifier,
                title: configuration.title ?? "",
                text: configuration.text
            )

        case .imagePicker:
            let step = ImageCaptureStep(identifier: configuration.identifier)
            step.title = configuration.title ?? "Capture Image"
            return step

        case .custom:
            // Handle custom active task types
            if configuration.identifier.contains("calibration") {
                let step = CalibrationStep(identifier: configuration.identifier)
                step.title = "Calibration"
                return step
            } else if configuration.identifier.contains("annotation") {
                let step = AnnotationStep(identifier: configuration.identifier)
                step.title = "Annotation"
                return step
            }
            return nil

        default:
            return nil
        }
    }
}

// MARK: - Answer Format Helpers

extension ActiveTaskBuilder {
    static func createImageAnswerFormat() -> ORKAnswerFormat {
        return ORKImageAnswerFormat()
    }

    static func createLocationAnswerFormat() -> ORKAnswerFormat {
        return ORKLocationAnswerFormat()
    }

    static func createHealthKitAnswerFormat(
        quantityType: HKQuantityType
    ) -> ORKAnswerFormat? {
        return ORKHealthKitQuantityTypeAnswerFormat(quantityType: quantityType)
    }
}
