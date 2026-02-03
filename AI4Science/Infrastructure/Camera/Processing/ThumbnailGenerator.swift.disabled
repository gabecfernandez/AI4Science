import UIKit
import AVFoundation
import os.log

/// Service for generating thumbnails for captures
actor ThumbnailGenerator {
    static let shared = ThumbnailGenerator()

    private let logger = Logger(subsystem: "com.ai4science.camera", category: "ThumbnailGenerator")

    enum ThumbnailError: LocalizedError {
        case invalidInput
        case generationFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidInput:
                return "Invalid input for thumbnail generation"
            case .generationFailed(let reason):
                return "Failed to generate thumbnail: \(reason)"
            }
        }
    }

    struct ThumbnailOptions {
        let size: CGSize
        let scale: CGFloat
        let cornerRadius: CGFloat?
        let borderWidth: CGFloat?
        let borderColor: UIColor?

        init(
            size: CGSize = CGSize(width: 120, height: 120),
            scale: CGFloat = UIScreen.main.scale,
            cornerRadius: CGFloat? = nil,
            borderWidth: CGFloat? = nil,
            borderColor: UIColor? = nil
        ) {
            self.size = size
            self.scale = scale
            self.cornerRadius = cornerRadius
            self.borderWidth = borderWidth
            self.borderColor = borderColor
        }
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Generate thumbnail from image data
    func generateThumbnail(
        from imageData: Data,
        options: ThumbnailOptions = ThumbnailOptions()
    ) async throws -> UIImage {
        guard let originalImage = UIImage(data: imageData) else {
            throw ThumbnailError.invalidInput
        }

        return try await generateThumbnail(from: originalImage, options: options)
    }

    /// Generate thumbnail from UIImage
    func generateThumbnail(
        from image: UIImage,
        options: ThumbnailOptions = ThumbnailOptions()
    ) async throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: options.size)

        let thumbnail = renderer.image { context in
            // Draw background
            UIColor.white.setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: options.size))

            // Calculate aspect ratio fit
            let aspectRatio = image.size.width / image.size.height
            var drawRect = CGRect(origin: .zero, size: options.size)

            if aspectRatio > 1 {
                let newHeight = options.size.width / aspectRatio
                drawRect.origin.y = (options.size.height - newHeight) / 2
                drawRect.size.height = newHeight
            } else {
                let newWidth = options.size.height * aspectRatio
                drawRect.origin.x = (options.size.width - newWidth) / 2
                drawRect.size.width = newWidth
            }

            // Apply corner radius if needed
            if let cornerRadius = options.cornerRadius {
                let path = UIBezierPath(
                    roundedRect: CGRect(origin: .zero, size: options.size),
                    cornerRadius: cornerRadius
                )
                path.addClip()
            }

            // Draw image
            image.draw(in: drawRect)

            // Draw border if needed
            if let borderWidth = options.borderWidth, let borderColor = options.borderColor {
                let borderRect = CGRect(origin: .zero, size: options.size)
                let borderPath = UIBezierPath(rect: borderRect)
                borderColor.setStroke()
                borderPath.lineWidth = borderWidth
                borderPath.stroke()
            }
        }

        logger.info("Thumbnail generated with size: \(options.size)")
        return thumbnail
    }

    /// Generate thumbnail from video
    func generateThumbnail(
        from videoURL: URL,
        at time: CMTime = .zero,
        options: ThumbnailOptions = ThumbnailOptions()
    ) async throws -> UIImage {
        let asset = AVAsset(url: videoURL)

        guard asset.isReadable else {
            throw ThumbnailError.invalidInput
        }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = options.size

        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            let image = UIImage(cgImage: cgImage)

            return try await generateThumbnail(from: image, options: options)
        } catch {
            logger.error("Failed to extract frame: \(error.localizedDescription)")
            throw ThumbnailError.generationFailed(error.localizedDescription)
        }
    }

    /// Generate multiple thumbnails from video
    func generateThumbnails(
        from videoURL: URL,
        count: Int = 4,
        options: ThumbnailOptions = ThumbnailOptions()
    ) async throws -> [UIImage] {
        let asset = AVAsset(url: videoURL)

        guard asset.isReadable else {
            throw ThumbnailError.invalidInput
        }

        let duration = asset.duration.seconds
        let interval = duration / Double(count)

        var thumbnails: [UIImage] = []

        for i in 0..<count {
            let time = CMTime(seconds: Double(i) * interval, preferredTimescale: 600)
            do {
                let thumbnail = try await generateThumbnail(
                    from: videoURL,
                    at: time,
                    options: options
                )
                thumbnails.append(thumbnail)
            } catch {
                logger.error("Failed to generate thumbnail \(i): \(error.localizedDescription)")
            }
        }

        logger.info("Generated \(thumbnails.count) video thumbnails")
        return thumbnails
    }

    /// Generate grid thumbnail from multiple images
    func generateGridThumbnail(
        from images: [UIImage],
        gridSize: CGSize = CGSize(width: 2, height: 2),
        options: ThumbnailOptions = ThumbnailOptions()
    ) async throws -> UIImage {
        let cols = Int(gridSize.width)
        let rows = Int(gridSize.height)
        let cellSize = CGSize(
            width: options.size.width / CGFloat(cols),
            height: options.size.height / CGFloat(rows)
        )

        let renderer = UIGraphicsImageRenderer(size: options.size)

        let gridThumbnail = renderer.image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: options.size)).fill()

            for (index, image) in images.enumerated() {
                if index >= cols * rows {
                    break
                }

                let row = index / cols
                let col = index % cols

                let rect = CGRect(
                    x: CGFloat(col) * cellSize.width,
                    y: CGFloat(row) * cellSize.height,
                    width: cellSize.width,
                    height: cellSize.height
                )

                image.draw(in: rect)
            }
        }

        logger.info("Grid thumbnail generated with \(images.count) images")
        return gridThumbnail
    }

    /// Generate data URL thumbnail
    func generateDataURLThumbnail(
        from image: UIImage,
        options: ThumbnailOptions = ThumbnailOptions()
    ) async throws -> String {
        let thumbnail = try await generateThumbnail(from: image, options: options)

        guard let imageData = thumbnail.jpegData(compressionQuality: 0.7) else {
            throw ThumbnailError.generationFailed("Failed to encode thumbnail")
        }

        let base64String = imageData.base64EncodedString()
        return "data:image/jpeg;base64,\(base64String)"
    }

    /// Generate placeholder thumbnail
    func generatePlaceholderThumbnail(
        size: CGSize = CGSize(width: 120, height: 120),
        backgroundColor: UIColor = .systemGray5,
        iconColor: UIColor = .systemGray3
    ) async -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)

        let placeholder = renderer.image { context in
            backgroundColor.setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: size))

            let iconSize = size.width * 0.4
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )

            iconColor.setStroke()
            let path = UIBezierPath(ovalIn: iconRect)
            path.lineWidth = 2
            path.stroke()

            let checkmarkPath = UIBezierPath()
            checkmarkPath.move(to: CGPoint(x: iconRect.midX - 5, y: iconRect.midY + 2))
            checkmarkPath.addLine(to: CGPoint(x: iconRect.midX - 1, y: iconRect.midY + 6))
            checkmarkPath.addLine(to: CGPoint(x: iconRect.midX + 8, y: iconRect.midY - 3))
            checkmarkPath.lineWidth = 2
            checkmarkPath.lineCapStyle = .round
            checkmarkPath.lineJoinStyle = .round
            iconColor.setStroke()
            checkmarkPath.stroke()
        }

        logger.info("Placeholder thumbnail generated")
        return placeholder
    }
}
