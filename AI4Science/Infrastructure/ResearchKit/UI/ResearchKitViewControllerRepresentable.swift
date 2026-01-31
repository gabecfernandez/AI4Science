import SwiftUI
import ResearchKit

/// SwiftUI wrapper for ResearchKit task view controller
struct ResearchKitViewControllerRepresentable: UIViewControllerRepresentable {
    // MARK: - Properties
    let task: ORKTask
    @Environment(\.dismiss) var dismiss
    var onCompletion: ((ORKTaskResult) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> ORKTaskViewController {
        let taskViewController = ORKTaskViewController(task: task, taskRun: NSUUID() as UUID)
        taskViewController.delegate = context.coordinator
        return taskViewController
    }

    func updateUIViewController(_ uiViewController: ORKTaskViewController, context: Context) {
        // Update if needed
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(
            onCompletion: onCompletion,
            onCancel: onCancel,
            dismiss: dismiss
        )
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, ORKTaskViewControllerDelegate {
        let onCompletion: ((ORKTaskResult) -> Void)?
        let onCancel: (() -> Void)?
        let dismiss: DismissAction

        init(
            onCompletion: ((ORKTaskResult) -> Void)?,
            onCancel: (() -> Void)?,
            dismiss: DismissAction
        ) {
            self.onCompletion = onCompletion
            self.onCancel = onCancel
            self.dismiss = dismiss
        }

        // MARK: - ORKTaskViewControllerDelegate

        func taskViewController(
            _ taskViewController: ORKTaskViewController,
            didFinishWith reason: ORKTaskViewControllerFinishReason,
            error: Error?
        ) {
            switch reason {
            case .completed:
                let result = taskViewController.result
                onCompletion?(result)

            case .discarded, .failed, .saved:
                onCancel?()
            }

            dismiss()
        }

        func taskViewControllerSupportsSaveAndRestore(_ taskViewController: ORKTaskViewController) -> Bool {
            return false
        }
    }
}

// MARK: - Preview
#if DEBUG
struct ResearchKitViewControllerRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        let step1 = ORKQuestionStep(identifier: "question1", title: "Sample Question", answer: ORKAnswerFormat.scale(withMaximumValue: 5, minimumValue: 1, defaultValue: 3, step: 1, vertical: false, maximumValueDescription: "Very satisfied", minimumValueDescription: "Very unsatisfied"))
        step1.isOptional = false

        let completionStep = ORKCompletionStep(identifier: "completion")
        completionStep.title = "Complete"
        completionStep.text = "Thank you for completing the task"

        let task = ORKOrderedTask(identifier: "previewTask", steps: [step1, completionStep])

        return ResearchKitViewControllerRepresentable(
            task: task,
            onCompletion: { result in
                print("Task completed: \(result.identifier)")
            },
            onCancel: {
                print("Task cancelled")
            }
        )
    }
}
#endif
