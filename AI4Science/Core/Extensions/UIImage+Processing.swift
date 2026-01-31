import UIKit

extension UIImage {
    /// Resize image to target size
    public func resized(to size: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Crop image to rect
    public func cropped(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let scale = self.scale
        let croppedCGImage = cgImage.cropping(to: CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        ))

        return croppedCGImage.map { UIImage(cgImage: $0, scale: scale, orientation: imageOrientation) }
    }

    /// Compress image to target quality
    public func compressed(quality: CGFloat) -> Data? {
        jpegData(compressionQuality: quality)
    }

    /// Rotate image by angle in degrees
    public func rotated(degrees: CGFloat) -> UIImage? {
        let radians = degrees * .pi / 180
        let newSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .size

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)

        return renderer.image { context in
            context.cgContext.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            context.cgContext.rotate(by: radians)
            draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        }
    }

    /// Apply blur effect
    public func blurred(radius: CGFloat) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let context = CIContext()
        let inputImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)

        guard let outputImage = filter?.outputImage,
              let outputCGImage = context.createCGImage(outputImage, from: inputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: outputCGImage, scale: scale, orientation: imageOrientation)
    }

    /// Grayscale image
    public func grayscaled() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let context = CIContext()
        let inputImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter?.setValue(0, forKey: kCIInputSaturationKey)

        guard let outputImage = filter?.outputImage,
              let outputCGImage = context.createCGImage(outputImage, from: inputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: outputCGImage, scale: scale, orientation: imageOrientation)
    }

    /// Scale image maintaining aspect ratio
    public func scaledAspectFit(to maxSize: CGSize) -> UIImage? {
        let aspect = size.width / size.height
        let targetSize: CGSize

        if aspect > 1 {
            targetSize = CGSize(width: maxSize.width, height: maxSize.width / aspect)
        } else {
            targetSize = CGSize(width: maxSize.height * aspect, height: maxSize.height)
        }

        return resized(to: targetSize)
    }

    /// Get image size in MB
    public var sizeInMB: Double {
        guard let data = pngData() ?? jpegData(compressionQuality: 1.0) else { return 0 }
        return Double(data.count) / (1024 * 1024)
    }

    /// Create thumbnail
    public func thumbnail(size: CGSize) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let nativeSize = CGSize(width: cgImage.width, height: cgImage.height)
        let aspect = nativeSize.width / nativeSize.height

        var scaledSize = size
        if aspect > 1 {
            scaledSize = CGSize(width: size.height * aspect, height: size.height)
        } else {
            scaledSize = CGSize(width: size.width, height: size.width / aspect)
        }

        return resized(to: scaledSize)?.cropped(to: CGRect(origin: .zero, size: size))
    }
}
