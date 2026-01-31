import ResearchKit
import UIKit

/// Custom instruction step with enhanced functionality
open class CustomInstructionStep: ORKInstructionStep {
    // MARK: - Properties

    open var backgroundColor: UIColor = .systemBackground
    open var titleColor: UIColor = .label
    open var textColor: UIColor = .secondaryLabel
    open var shouldShowContinueButton: Bool = true
    open var shouldShowSkipButton: Bool = false
    open var customImage: UIImage?
    open var imageContentMode: UIView.ContentMode = .scaleAspectFit
    open var audioURL: URL?
    open var shouldAutoPlayAudio: Bool = false
    open var estimatedDuration: TimeInterval?
    open var metadata: [String: Any] = [:]

    // MARK: - Initialization

    public override init(identifier: String) {
        super.init(identifier: identifier)
        setupDefaults()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefaults()
    }

    // MARK: - Configuration

    private func setupDefaults() {
        backgroundColor = .systemBackground
        titleColor = .label
        textColor = .secondaryLabel
    }

    /// Configure with custom styling
    public func configure(
        title: String,
        text: String,
        image: UIImage? = nil,
        backgroundColor: UIColor = .systemBackground,
        titleColor: UIColor = .label,
        textColor: UIColor = .secondaryLabel
    ) {
        self.title = title
        self.text = text
        self.image = image
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor
        self.textColor = textColor
    }

    /// Set audio content
    public func setAudio(url: URL, autoPlay: Bool = false) {
        audioURL = url
        shouldAutoPlayAudio = autoPlay
    }

    /// Add metadata
    public func addMetadata(key: String, value: Any) {
        metadata[key] = value
    }
}

// MARK: - Custom Instruction Step View Controller

open class CustomInstructionStepViewController: ORKInstructionStepViewController {
    // MARK: - Properties

    private let customStep: CustomInstructionStep?
    private var audioPlayer: AVAudioPlayer?
    private let audioSession = AVAudioSession.sharedInstance()

    // MARK: - Initialization

    override open func viewDidLoad() {
        super.viewDidLoad()

        customStep = step as? CustomInstructionStep

        if let customStep = customStep {
            applyCustomStyling(customStep)
            setupAudio(customStep)
        }
    }

    // MARK: - Private Helpers

    private func applyCustomStyling(_ customStep: CustomInstructionStep) {
        view.backgroundColor = customStep.backgroundColor

        // Update title label styling
        if let titleLabel = instructionLabel {
            titleLabel.textColor = customStep.titleColor
            titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        }

        // Update text label styling
        if let textLabel = detailLabel {
            textLabel.textColor = customStep.textColor
            textLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }

        // Update image
        if let customImage = customStep.customImage {
            imageView?.image = customImage
            imageView?.contentMode = customStep.imageContentMode
        }
    }

    private func setupAudio(_ customStep: CustomInstructionStep) {
        guard let audioURL = customStep.audioURL else { return }

        do {
            try audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self

            if customStep.shouldAutoPlayAudio {
                audioPlayer?.play()
            }
        } catch {
            print("Error loading audio: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio Controls

    public func playAudio() {
        audioPlayer?.play()
    }

    public func pauseAudio() {
        audioPlayer?.pause()
    }

    public func stopAudio() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
    }
}

// MARK: - AVAudioPlayerDelegate

extension CustomInstructionStepViewController: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        // Handle audio completion
    }

    public func audioPlayerDecodeErrorDidOccur(
        _ player: AVAudioPlayer,
        error: Error?
    ) {
        print("Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
    }
}

// MARK: - Builder Extension

extension CustomInstructionStep {
    /// Create a themed instruction step
    public static func create(
        identifier: String,
        title: String,
        description: String,
        theme: InstructionStepTheme = .default
    ) -> CustomInstructionStep {
        let step = CustomInstructionStep(identifier: identifier)
        step.title = title
        step.text = description

        switch theme {
        case .default:
            step.backgroundColor = .systemBackground
            step.titleColor = .label
            step.textColor = .secondaryLabel

        case .attention:
            step.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
            step.titleColor = .systemRed
            step.textColor = .label

        case .success:
            step.backgroundColor = UIColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0)
            step.titleColor = .systemGreen
            step.textColor = .label

        case .informational:
            step.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
            step.titleColor = .systemBlue
            step.textColor = .label
        }

        return step
    }

    enum InstructionStepTheme {
        case `default`
        case attention
        case success
        case informational
    }
}
