import SwiftUI
import AVFoundation

/// UIViewRepresentable for camera preview using AVCaptureVideoPreviewLayer
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession?
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    var onFrameAvailable: ((CMSampleBuffer) -> Void)?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        if let session = session {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = videoGravity
            view.layer.addSublayer(previewLayer)

            context.coordinator.previewLayer = previewLayer
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            previewLayer.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - CameraPreviewViewWithOverlay

/// Camera preview with overlay support
struct CameraPreviewViewWithOverlay: UIViewRepresentable {
    let session: AVCaptureSession?
    let onOverlayView: (UIView) -> Void
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .black

        if let session = session {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = videoGravity
            containerView.layer.addSublayer(previewLayer)

            context.coordinator.previewLayer = previewLayer
        }

        // Create overlay view
        let overlayView = UIView()
        overlayView.backgroundColor = .clear
        containerView.addSubview(overlayView)

        context.coordinator.overlayView = overlayView

        // Call the callback with overlay view
        onOverlayView(overlayView)

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            previewLayer.frame = uiView.bounds
        }

        if let overlayView = context.coordinator.overlayView {
            overlayView.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var overlayView: UIView?
    }
}

// MARK: - PreviewFocusIndicator

/// Visual indicator for tap to focus
struct PreviewFocusIndicator: UIViewRepresentable {
    let isVisible: Bool
    let position: CGPoint

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Clear previous indicators
        uiView.subviews.forEach { $0.removeFromSuperview() }

        if isVisible {
            let indicatorSize: CGFloat = 80
            let indicator = UIView()
            indicator.frame = CGRect(
                x: position.x - indicatorSize / 2,
                y: position.y - indicatorSize / 2,
                width: indicatorSize,
                height: indicatorSize
            )
            indicator.layer.borderWidth = 2
            indicator.layer.borderColor = UIColor.white.cgColor
            indicator.layer.cornerRadius = indicatorSize / 2

            uiView.addSubview(indicator)

            // Animate the indicator
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    indicator.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                },
                completion: { _ in
                    UIView.animate(
                        withDuration: 0.2,
                        delay: 0.5,
                        options: .curveEaseInOut,
                        animations: {
                            indicator.alpha = 0
                        },
                        completion: { _ in
                            indicator.removeFromSuperview()
                        }
                    )
                }
            )
        }
    }
}

// MARK: - CameraGridOverlay

/// Grid overlay for composition
struct CameraGridOverlay: UIViewRepresentable {
    let isVisible: Bool
    let gridStyle: GridStyle

    enum GridStyle {
        case thirdRule
        case centered
        case custom(columns: Int, rows: Int)

        var description: String {
            switch self {
            case .thirdRule:
                return "Rule of Thirds"
            case .centered:
                return "Centered"
            case .custom(let cols, let rows):
                return "Grid \(cols)x\(rows)"
            }
        }
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Clear previous grid
        uiView.layer.sublayers?.removeAll()

        if isVisible {
            drawGrid(on: uiView)
        }
    }

    private func drawGrid(on view: UIView) {
        let (cols, rows) = getGridDimensions()

        let cellWidth = view.bounds.width / CGFloat(cols)
        let cellHeight = view.bounds.height / CGFloat(rows)

        // Draw vertical lines
        for i in 1..<cols {
            let path = UIBezierPath()
            let x = CGFloat(i) * cellWidth
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: view.bounds.height))

            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.strokeColor = UIColor.white.withAlphaComponent(0.3).cgColor
            shapeLayer.lineWidth = 0.5
            view.layer.addSublayer(shapeLayer)
        }

        // Draw horizontal lines
        for i in 1..<rows {
            let path = UIBezierPath()
            let y = CGFloat(i) * cellHeight
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: view.bounds.width, y: y))

            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.strokeColor = UIColor.white.withAlphaComponent(0.3).cgColor
            shapeLayer.lineWidth = 0.5
            view.layer.addSublayer(shapeLayer)
        }
    }

    private func getGridDimensions() -> (cols: Int, rows: Int) {
        switch gridStyle {
        case .thirdRule:
            return (3, 3)
        case .centered:
            return (2, 2)
        case .custom(let cols, let rows):
            return (cols, rows)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Text("Camera Preview")
                .foregroundColor(.white)
        }
    }
}
