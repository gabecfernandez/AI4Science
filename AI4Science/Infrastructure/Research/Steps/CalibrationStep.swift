import ResearchKit
import UIKit
import AVFoundation

/// Custom step for camera calibration
open class CalibrationStep: ORKStep {
    // MARK: - Properties

    open var referenceSize: CGSize = CGSize(width: 0.05, height: 0.05) // meters
    open var calibrationMode: CalibrationMode = .colorChart
    open var targetMarkerSize: CGFloat = 50.0
    open var allowsRetry: Bool = true
    open var maxRetries: Int = 3
    open var calibrationResult: CalibrationResult?

    enum CalibrationMode {
        case colorChart
        case checkerboard
        case qrCode
        case customMarker
    }

    // MARK: - Initialization

    public override init(identifier: String) {
        super.init(identifier: identifier)
        setupDefaults()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefaults()
    }

    private func setupDefaults() {
        title = "Camera Calibration"
        text = "Calibrate your camera for accurate measurements"
    }

    public func configure(
        referenceSize: CGSize,
        mode: CalibrationMode = .colorChart
    ) {
        self.referenceSize = referenceSize
        calibrationMode = mode
    }
}

// MARK: - Calibration Models

struct CalibrationResult: Codable {
    let id: String = UUID().uuidString
    let timestamp: Date
    let calibrationMode: String
    let focalLength: Double
    let sensorWidth: Double
    let principalPointX: Double
    let principalPointY: Double
    let distortionCoefficients: [Double]
    let qualityScore: Double // 0.0 to 1.0

    var isValid: Bool {
        qualityScore >= 0.7
    }
}

struct CalibrationPoint {
    let imageCoordinate: CGPoint
    let worldCoordinate: CGPoint
    let confidence: Double
}

// MARK: - Calibration View

class CalibrationView: UIView {
    // MARK: - Properties

    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }

    var calibrationMode: CalibrationStep.CalibrationMode = .colorChart
    var targetMarkerSize: CGFloat = 50.0

    private let imageView = UIImageView()
    private let overlayView = UIView()
    private var calibrationPoints: [CalibrationPoint] = []
    private let cameraSession = AVCaptureSession()
    var capturedImage: UIImage?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .black

        addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true

        addSubview(overlayView)
        overlayView.backgroundColor = .clear

        imageView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Calibration Guide Drawing

    func drawCalibrationGuide() {
        overlayView.setNeedsDisplay()

        let path = UIBezierPath()
        let center = overlayView.center
        let size = targetMarkerSize

        switch calibrationMode {
        case .colorChart:
            drawColorChart(in: overlayView, center: center)

        case .checkerboard:
            drawCheckerboard(in: overlayView, size: size)

        case .qrCode:
            drawQRCodeFrame(in: overlayView, center: center, size: size)

        case .customMarker:
            drawCustomMarker(in: overlayView, center: center, size: size)
        }
    }

    private func drawColorChart(in view: UIView, center: CGPoint) {
        let colors: [UIColor] = [
            .systemRed, .systemGreen, .systemBlue,
            .systemYellow, .cyan, .magenta
        ]

        let squareSize: CGFloat = 40
        let spacing: CGFloat = 5
        let totalWidth = CGFloat(colors.count) * squareSize + CGFloat(colors.count - 1) * spacing

        var x = center.x - totalWidth / 2
        for color in colors {
            let rect = CGRect(x: x, y: center.y - squareSize / 2, width: squareSize, height: squareSize)
            let layer = CALayer()
            layer.backgroundColor = color.cgColor
            layer.frame = rect
            view.layer.addSublayer(layer)
            x += squareSize + spacing
        }
    }

    private func drawCheckerboard(in view: UIView, size: CGFloat) {
        let squareCount = 8
        let squareSize = size / CGFloat(squareCount)

        for row in 0..<squareCount {
            for col in 0..<squareCount {
                let isBlack = (row + col) % 2 == 0
                let color: UIColor = isBlack ? .black : .white

                let x = view.center.x - size / 2 + CGFloat(col) * squareSize
                let y = view.center.y - size / 2 + CGFloat(row) * squareSize

                let rect = CGRect(x: x, y: y, width: squareSize, height: squareSize)
                let layer = CALayer()
                layer.backgroundColor = color.cgColor
                layer.frame = rect
                view.layer.addSublayer(layer)
            }
        }
    }

    private func drawQRCodeFrame(in view: UIView, center: CGPoint, size: CGFloat) {
        let frameView = UIView()
        frameView.layer.borderColor = UIColor.systemGreen.cgColor
        frameView.layer.borderWidth = 3
        frameView.frame = CGRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)
        view.addSubview(frameView)

        // Draw corner markers
        let markerSize: CGFloat = 10
        let corners = [
            CGPoint(x: center.x - size / 2, y: center.y - size / 2),
            CGPoint(x: center.x + size / 2, y: center.y - size / 2),
            CGPoint(x: center.x - size / 2, y: center.y + size / 2),
            CGPoint(x: center.x + size / 2, y: center.y + size / 2)
        ]

        for corner in corners {
            let marker = UIView()
            marker.backgroundColor = .systemGreen
            marker.frame = CGRect(
                x: corner.x - markerSize / 2,
                y: corner.y - markerSize / 2,
                width: markerSize,
                height: markerSize
            )
            marker.layer.cornerRadius = markerSize / 2
            view.addSubview(marker)
        }
    }

    private func drawCustomMarker(in view: UIView, center: CGPoint, size: CGFloat) {
        let markerView = UIView()
        markerView.layer.borderColor = UIColor.systemBlue.cgColor
        markerView.layer.borderWidth = 2
        markerView.frame = CGRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)
        markerView.layer.cornerRadius = size / 2
        view.addSubview(markerView)
    }

    // MARK: - Calibration Point Detection

    func detectCalibrationPoints() {
        guard let image = capturedImage else { return }

        // Use image processing to detect calibration points
        // This is a placeholder - actual implementation would use computer vision
        detectColorChartPoints(in: image)
    }

    private func detectColorChartPoints(in image: UIImage) {
        // Placeholder for color detection algorithm
        // In a real implementation, this would:
        // 1. Convert image to HSV color space
        // 2. Detect color regions
        // 3. Calculate centroids
        // 4. Map to world coordinates

        let colors: [UIColor] = [
            .systemRed, .systemGreen, .systemBlue,
            .systemYellow, .cyan, .magenta
        ]

        for (index, color) in colors.enumerated() {
            let point = CalibrationPoint(
                imageCoordinate: CGPoint(x: CGFloat(index) * 50, y: bounds.midY),
                worldCoordinate: CGPoint(x: CGFloat(index) * 0.05, y: 0),
                confidence: 0.95
            )
            calibrationPoints.append(point)
        }
    }

    // MARK: - Camera Capture

    func captureCalibrationImage() {
        // This would capture from camera in actual implementation
        // For now, we'll use the current image
    }
}

// MARK: - Calibration View Controller

open class CalibrationViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    // MARK: - Properties

    private let calibrationStep: CalibrationStep
    private let calibrationView = CalibrationView()
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var calibrationResult: CalibrationResult?
    private let completionHandler: ((CalibrationResult?) -> Void)?

    // UI Elements
    private let captureButton = UIButton()
    private let retryButton = UIButton()
    private let statusLabel = UILabel()
    private var retryCount = 0

    // MARK: - Initialization

    init(
        step: CalibrationStep,
        completionHandler: ((CalibrationResult?) -> Void)? = nil
    ) {
        self.calibrationStep = step
        self.completionHandler = completionHandler
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupCamera()
        setupCalibration()
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .black
        title = calibrationStep.title

        // Calibration view
        view.addSubview(calibrationView)
        calibrationView.translatesAutoresizingMaskIntoConstraints = false

        // Status label
        statusLabel.text = "Position calibration target in frame"
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        view.addSubview(statusLabel)

        // Capture button
        captureButton.setTitle("Capture", for: .normal)
        captureButton.backgroundColor = .systemGreen
        captureButton.setTitleColor(.white, for: .normal)
        captureButton.layer.cornerRadius = 8
        captureButton.addTarget(self, action: #selector(captureCalibration), for: .touchUpInside)
        view.addSubview(captureButton)

        // Retry button
        retryButton.setTitle("Retry", for: .normal)
        retryButton.backgroundColor = .systemBlue
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.layer.cornerRadius = 8
        retryButton.addTarget(self, action: #selector(retryCalibration), for: .touchUpInside)
        retryButton.isHidden = true
        view.addSubview(retryButton)

        setupConstraints()
    }

    private func setupConstraints() {
        calibrationView.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            calibrationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calibrationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calibrationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calibrationView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -16),

            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statusLabel.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -16),

            captureButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            captureButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            captureButton.heightAnchor.constraint(equalToConstant: 44),

            retryButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 8),
            retryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            retryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            retryButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Camera Setup

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            statusLabel.text = "Camera not available"
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            captureSession?.addInput(input)

            photoOutput = AVCapturePhotoOutput()
            if let photoOutput = photoOutput {
                captureSession?.addOutput(photoOutput)
            }

            captureSession?.startRunning()
        } catch {
            statusLabel.text = "Camera setup failed"
        }
    }

    // MARK: - Calibration Setup

    private func setupCalibration() {
        calibrationView.calibrationMode = calibrationStep.calibrationMode
        calibrationView.targetMarkerSize = calibrationStep.targetMarkerSize
        calibrationView.drawCalibrationGuide()
    }

    // MARK: - Actions

    @objc private func captureCalibration() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    @objc private func retryCalibration() {
        retryCount += 1
        if retryCount >= calibrationStep.maxRetries {
            showMaxRetriesAlert()
        } else {
            setupCalibration()
            retryButton.isHidden = true
            captureButton.isHidden = false
            statusLabel.text = "Position calibration target in frame"
        }
    }

    // MARK: - Photo Capture Delegate

    public func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            statusLabel.text = "Failed to capture image"
            return
        }

        processCalibrationImage(image)
    }

    // MARK: - Calibration Processing

    private func processCalibrationImage(_ image: UIImage) {
        calibrationView.capturedImage = image
        calibrationView.detectCalibrationPoints()

        // Compute calibration
        let result = computeCalibration(image)

        if result.isValid {
            calibrationResult = result
            showCalibrationSuccess()
        } else {
            showCalibrationRetry()
        }
    }

    private func computeCalibration(_ image: UIImage) -> CalibrationResult {
        // Placeholder for actual calibration computation
        // In a real implementation, this would:
        // 1. Detect calibration points
        // 2. Compute camera matrix (focal length, principal point)
        // 3. Estimate distortion coefficients
        // 4. Assess calibration quality

        return CalibrationResult(
            timestamp: Date(),
            calibrationMode: String(describing: calibrationStep.calibrationMode),
            focalLength: 1000.0,
            sensorWidth: 0.006,
            principalPointX: 320.0,
            principalPointY: 240.0,
            distortionCoefficients: [],
            qualityScore: 0.85
        )
    }

    private func showCalibrationSuccess() {
        captureButton.isHidden = true
        retryButton.isHidden = true
        statusLabel.text = "Calibration successful!"
        statusLabel.textColor = .systemGreen

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.completionHandler?(self?.calibrationResult)
        }
    }

    private func showCalibrationRetry() {
        captureButton.isHidden = true
        retryButton.isHidden = false
        statusLabel.text = "Calibration quality low. Retry?"
        statusLabel.textColor = .systemOrange
    }

    private func showMaxRetriesAlert() {
        let alert = UIAlertController(
            title: "Max Retries Reached",
            message: "Unable to complete calibration after \(calibrationStep.maxRetries) attempts",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.completionHandler?(nil)
        })
        present(alert, animated: true)
    }
}
