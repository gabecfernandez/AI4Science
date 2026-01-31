import ResearchKit
import UIKit
import AVFoundation

/// Custom step for capturing and managing images
open class ImageCaptureStep: ORKStep {
    // MARK: - Properties

    open var maxImageCount: Int = 1
    open var useGrid: Bool = true
    open var gridSize: CGFloat = 3
    open var allowsEditing: Bool = true
    open var cameraPosition: AVCaptureDevice.Position = .back
    open var flashMode: AVCaptureDevice.FlashMode = .auto
    open var capturedImages: [UIImage] = []
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

    private func setupDefaults() {
        title = "Capture Image"
        text = "Take a photo for analysis"
    }

    /// Configure image capture
    public func configure(
        maxImages: Int = 1,
        useGrid: Bool = true,
        allowsEditing: Bool = true,
        cameraPosition: AVCaptureDevice.Position = .back
    ) {
        maxImageCount = maxImages
        self.useGrid = useGrid
        self.allowsEditing = allowsEditing
        self.cameraPosition = cameraPosition
    }
}

// MARK: - Image Capture View Controller

open class ImageCaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Properties

    private let captureStep: ImageCaptureStep
    private let imagePicker = UIImagePickerController()
    private var capturedImages: [UIImage] = []
    private let completionHandler: (([UIImage]) -> Void)?

    // UI Elements
    private let cameraButton = UIButton()
    private let libraryButton = UIButton()
    private let imagesCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )
    private let gridOverlayView = GridOverlayView()

    // MARK: - Initialization

    init(
        step: ImageCaptureStep,
        completionHandler: (([UIImage]) -> Void)? = nil
    ) {
        self.captureStep = step
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
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = captureStep.title

        // Camera button
        cameraButton.setTitle("Take Photo", for: .normal)
        cameraButton.backgroundColor = .systemBlue
        cameraButton.setTitleColor(.white, for: .normal)
        cameraButton.layer.cornerRadius = 8
        cameraButton.addTarget(self, action: #selector(openCamera), for: .touchUpInside)
        view.addSubview(cameraButton)

        // Library button
        libraryButton.setTitle("Choose from Library", for: .normal)
        libraryButton.backgroundColor = .systemGreen
        libraryButton.setTitleColor(.white, for: .normal)
        libraryButton.layer.cornerRadius = 8
        libraryButton.addTarget(self, action: #selector(openLibrary), for: .touchUpInside)
        view.addSubview(libraryButton)

        // Collection view for captured images
        imagesCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        imagesCollectionView.register(
            ImageCell.self,
            forCellWithReuseIdentifier: "ImageCell"
        )
        view.addSubview(imagesCollectionView)

        setupConstraints()
    }

    private func setupConstraints() {
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        libraryButton.translatesAutoresizingMaskIntoConstraints = false
        imagesCollectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cameraButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cameraButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8),
            cameraButton.heightAnchor.constraint(equalToConstant: 44),

            libraryButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            libraryButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 8),
            libraryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            libraryButton.heightAnchor.constraint(equalToConstant: 44),

            imagesCollectionView.topAnchor.constraint(equalTo: cameraButton.bottomAnchor, constant: 16),
            imagesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imagesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imagesCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Camera Setup

    private func setupCamera() {
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.cameraCaptureMode = .photo
        imagePicker.allowsEditing = captureStep.allowsEditing

        // Configure camera position
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            imagePicker.cameraDevice = captureStep.cameraPosition == .front ? .front : .rear
        }
    }

    // MARK: - Actions

    @objc private func openCamera() {
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            requestCameraPermission()
            return
        }

        imagePicker.sourceType = .camera
        present(imagePicker, animated: true)
    }

    @objc private func openLibrary() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.openCamera()
                } else {
                    self?.showPermissionError()
                }
            }
        }
    }

    private func showPermissionError() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to capture images",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Image Picker Delegate

    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image: UIImage?

        if let editedImage = info[.editedImage] as? UIImage {
            image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            image = originalImage
        } else {
            image = nil
        }

        if let image = image, capturedImages.count < captureStep.maxImageCount {
            capturedImages.append(image)
            imagesCollectionView.reloadData()
        }

        dismiss(animated: true)
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    // MARK: - Public Methods

    public func getImages() -> [UIImage] {
        capturedImages
    }

    public func clearImages() {
        capturedImages.removeAll()
        imagesCollectionView.reloadData()
    }
}

// MARK: - Collection View Delegate & Data Source

extension ImageCaptureViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        capturedImages.count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ImageCell",
            for: indexPath
        ) as? ImageCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: capturedImages[indexPath.item])
        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let itemsPerRow: CGFloat = 3
        let padding: CGFloat = 16
        let availableWidth = collectionView.bounds.width - padding
        let itemDimension = availableWidth / itemsPerRow

        return CGSize(width: itemDimension, height: itemDimension)
    }
}

// MARK: - Image Cell

private class ImageCell: UICollectionViewCell {
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with image: UIImage) {
        imageView.image = image
    }
}

// MARK: - Grid Overlay View

private class GridOverlayView: UIView {
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setLineWidth(1.0)
        context.setStrokeColor(UIColor.white.cgColor)

        let width = rect.width / 3
        let height = rect.height / 3

        for i in 1..<3 {
            // Vertical lines
            context.move(to: CGPoint(x: CGFloat(i) * width, y: 0))
            context.addLine(to: CGPoint(x: CGFloat(i) * width, y: rect.height))

            // Horizontal lines
            context.move(to: CGPoint(x: 0, y: CGFloat(i) * height))
            context.addLine(to: CGPoint(x: rect.width, y: CGFloat(i) * height))
        }

        context.strokePath()
    }
}
