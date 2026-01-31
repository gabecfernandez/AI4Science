import ResearchKit
import UIKit

/// Step for annotating defects or regions of interest in images
open class AnnotationStep: ORKStep {
    // MARK: - Properties

    open var image: UIImage?
    open var allowsMultipleAnnotations: Bool = true
    open var annotationColor: UIColor = .systemRed
    open var lineWidth: CGFloat = 2.0
    open var annotations: [ImageAnnotation] = []
    open var allowsErasing: Bool = true
    open var captureAnnotationMetadata: Bool = true

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
        title = "Annotate Image"
        text = "Mark any areas of interest or defects"
    }

    /// Configure annotation step
    public func configure(
        image: UIImage,
        allowsMultiple: Bool = true,
        color: UIColor = .systemRed,
        lineWidth: CGFloat = 2.0
    ) {
        self.image = image
        allowsMultipleAnnotations = allowsMultiple
        annotationColor = color
        self.lineWidth = lineWidth
    }
}

// MARK: - Image Annotation Model

struct ImageAnnotation: Codable {
    enum AnnotationType: String, Codable {
        case point
        case line
        case rectangle
        case circle
        case freeform
    }

    let id: String = UUID().uuidString
    let type: AnnotationType
    let points: [CGPoint]
    let color: String
    let lineWidth: CGFloat
    let timestamp: Date
    var label: String = ""
    var metadata: [String: String] = [:]

    enum CodingKeys: String, CodingKey {
        case id, type, color, lineWidth, timestamp, label, metadata
    }

    init(
        type: AnnotationType,
        points: [CGPoint],
        color: String = "#FF0000",
        lineWidth: CGFloat = 2.0,
        label: String = ""
    ) {
        self.type = type
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.label = label
        timestamp = Date()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(AnnotationType.self, forKey: .type)
        color = try container.decode(String.self, forKey: .color)
        lineWidth = try container.decode(CGFloat.self, forKey: .lineWidth)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]

        // Note: CGPoint arrays require custom decoding
        points = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(color, forKey: .color)
        try container.encode(lineWidth, forKey: .lineWidth)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(label, forKey: .label)
        try container.encode(metadata, forKey: .metadata)
    }
}

// MARK: - Annotation View

class AnnotationView: UIView {
    // MARK: - Properties

    var image: UIImage? {
        didSet {
            setNeedsDisplay()
        }
    }

    var annotations: [ImageAnnotation] = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    var currentAnnotationType: ImageAnnotation.AnnotationType = .freeform
    var annotationColor: UIColor = .systemRed
    var lineWidth: CGFloat = 2.0

    private var isDrawing = false
    private var currentPath: UIBezierPath?
    private var currentPoints: [CGPoint] = []
    private let imageView = UIImageView()

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
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        imageView.image = image
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        isDrawing = true
        currentPoints = [point]
        currentPath = UIBezierPath()
        currentPath?.move(to: point)

        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isDrawing else { return }
        let point = touch.location(in: self)

        currentPoints.append(point)
        currentPath?.addLine(to: point)

        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing else { return }

        isDrawing = false

        let annotation = ImageAnnotation(
            type: currentAnnotationType,
            points: currentPoints,
            color: annotationColor.toHexString(),
            lineWidth: lineWidth
        )

        annotations.append(annotation)
        currentPath = nil
        currentPoints = []

        setNeedsDisplay()
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        // Draw existing annotations
        for annotation in annotations {
            drawAnnotation(annotation)
        }

        // Draw current annotation being drawn
        if let currentPath = currentPath {
            annotationColor.setStroke()
            currentPath.lineWidth = lineWidth
            currentPath.stroke()
        }
    }

    private func drawAnnotation(_ annotation: ImageAnnotation) {
        guard let color = UIColor(hex: annotation.color) else { return }

        color.setStroke()
        color.withAlphaComponent(0.3).setFill()

        let path = UIBezierPath()

        switch annotation.type {
        case .point:
            if let first = annotation.points.first {
                let pointPath = UIBezierPath(
                    arcCenter: first,
                    radius: annotation.lineWidth * 3,
                    startAngle: 0,
                    endAngle: CGFloat.pi * 2,
                    clockwise: true
                )
                pointPath.lineWidth = annotation.lineWidth
                color.setStroke()
                pointPath.stroke()
            }

        case .line:
            if annotation.points.count >= 2 {
                path.move(to: annotation.points[0])
                for point in annotation.points.dropFirst() {
                    path.addLine(to: point)
                }
            }

        case .rectangle:
            if annotation.points.count >= 2 {
                let rect = CGRect(
                    x: min(annotation.points[0].x, annotation.points[1].x),
                    y: min(annotation.points[0].y, annotation.points[1].y),
                    width: abs(annotation.points[0].x - annotation.points[1].x),
                    height: abs(annotation.points[0].y - annotation.points[1].y)
                )
                path.append(UIBezierPath(rect: rect))
            }

        case .circle:
            if annotation.points.count >= 2 {
                let radius = annotation.points[0].distance(to: annotation.points[1])
                let circlePath = UIBezierPath(
                    arcCenter: annotation.points[0],
                    radius: radius,
                    startAngle: 0,
                    endAngle: CGFloat.pi * 2,
                    clockwise: true
                )
                path.append(circlePath)
            }

        case .freeform:
            if annotation.points.count > 0 {
                path.move(to: annotation.points[0])
                for point in annotation.points.dropFirst() {
                    path.addLine(to: point)
                }
            }
        }

        path.lineWidth = annotation.lineWidth
        color.setStroke()
        path.stroke()
        color.withAlphaComponent(0.2).setFill()
        path.fill()
    }

    // MARK: - Public Methods

    public func clearAnnotations() {
        annotations.removeAll()
        setNeedsDisplay()
    }

    public func removeLastAnnotation() {
        if !annotations.isEmpty {
            annotations.removeLast()
            setNeedsDisplay()
        }
    }

    public func getAnnotations() -> [ImageAnnotation] {
        annotations
    }

    public func setAnnotationType(_ type: ImageAnnotation.AnnotationType) {
        currentAnnotationType = type
    }
}

// MARK: - Annotation View Controller

open class AnnotationViewController: UIViewController {
    // MARK: - Properties

    private let annotationStep: AnnotationStep
    private let annotationView = AnnotationView()
    private let completionHandler: (([ImageAnnotation]) -> Void)?

    // UI Controls
    private let toolbarView = UIView()
    private let undoButton = UIButton()
    private let clearButton = UIButton()
    private let typeSegmentedControl = UISegmentedControl()

    // MARK: - Initialization

    init(
        step: AnnotationStep,
        completionHandler: (([ImageAnnotation]) -> Void)? = nil
    ) {
        self.annotationStep = step
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
        setupAnnotationView()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = annotationStep.title

        // Annotation view
        annotationView.image = annotationStep.image
        annotationView.annotationColor = annotationStep.annotationColor
        annotationView.lineWidth = annotationStep.lineWidth
        view.addSubview(annotationView)

        // Toolbar
        setupToolbar()
        view.addSubview(toolbarView)

        setupConstraints()
    }

    private func setupToolbar() {
        toolbarView.backgroundColor = .secondarySystemBackground

        // Undo button
        undoButton.setTitle("Undo", for: .normal)
        undoButton.setTitleColor(.systemBlue, for: .normal)
        undoButton.addTarget(self, action: #selector(undoAnnotation), for: .touchUpInside)
        toolbarView.addSubview(undoButton)

        // Clear button
        clearButton.setTitle("Clear", for: .normal)
        clearButton.setTitleColor(.systemRed, for: .normal)
        clearButton.addTarget(self, action: #selector(clearAnnotations), for: .touchUpInside)
        toolbarView.addSubview(clearButton)

        // Type selector
        typeSegmentedControl.insertSegment(withTitle: "Freeform", at: 0, animated: false)
        typeSegmentedControl.insertSegment(withTitle: "Rectangle", at: 1, animated: false)
        typeSegmentedControl.insertSegment(withTitle: "Circle", at: 2, animated: false)
        typeSegmentedControl.selectedSegmentIndex = 0
        typeSegmentedControl.addTarget(self, action: #selector(changeAnnotationType), for: .valueChanged)
        toolbarView.addSubview(typeSegmentedControl)
    }

    private func setupConstraints() {
        annotationView.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        typeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            annotationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            annotationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            annotationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            annotationView.bottomAnchor.constraint(equalTo: toolbarView.topAnchor),

            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: 60),

            undoButton.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 16),
            undoButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),

            clearButton.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -16),
            clearButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),

            typeSegmentedControl.centerXAnchor.constraint(equalTo: toolbarView.centerXAnchor),
            typeSegmentedControl.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            typeSegmentedControl.widthAnchor.constraint(equalToConstant: 200)
        ])
    }

    private func setupAnnotationView() {
        annotationView.backgroundColor = .clear
    }

    // MARK: - Actions

    @objc private func undoAnnotation() {
        annotationView.removeLastAnnotation()
    }

    @objc private func clearAnnotations() {
        annotationView.clearAnnotations()
    }

    @objc private func changeAnnotationType() {
        let types: [ImageAnnotation.AnnotationType] = [.freeform, .rectangle, .circle]
        annotationView.setAnnotationType(types[typeSegmentedControl.selectedSegmentIndex])
    }

    // MARK: - Public Methods

    public func getAnnotations() -> [ImageAnnotation] {
        annotationView.getAnnotations()
    }
}

// MARK: - Extensions

extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0

        return String(format: "#%06x", rgb)
    }

    convenience init?(hex: String) {
        let r, g, b: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat((hexNumber & 0x0000ff)) / 255

                    self.init(red: r, green: g, blue: b, alpha: 1)
                    return
                }
            }
        }

        return nil
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let xDist = self.x - point.x
        let yDist = self.y - point.y
        return sqrt(xDist * xDist + yDist * yDist)
    }
}
