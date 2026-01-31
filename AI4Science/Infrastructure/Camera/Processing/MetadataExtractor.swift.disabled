import UIKit
import ImageIO
import AVFoundation
import os.log

/// Service for extracting EXIF and camera metadata
actor MetadataExtractor {
    static let shared = MetadataExtractor()

    private let logger = Logger(subsystem: "com.ai4science.camera", category: "MetadataExtractor")

    enum MetadataError: LocalizedError {
        case invalidImage
        case metadataNotAvailable
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Invalid image data"
            case .metadataNotAvailable:
                return "Metadata is not available"
            case .decodingFailed:
                return "Failed to decode metadata"
            }
        }
    }

    struct ImageMetadata {
        let exif: EXIFData?
        let iptc: IPTCData?
        let raw: [String: Any]

        init(exif: EXIFData? = nil, iptc: IPTCData? = nil, raw: [String: Any] = [:]) {
            self.exif = exif
            self.iptc = iptc
            self.raw = raw
        }
    }

    struct EXIFData {
        let make: String?
        let model: String?
        let dateTime: Date?
        let orientation: Int?
        let exposureTime: Double?
        let fNumber: Double?
        let isoSpeedRatings: [Int]?
        let focalLength: Double?
        let focusDistance: Double?
        let lensModel: String?
        let brightnessValue: Double?
        let exposureBiasValue: Double?
        let meteringMode: Int?
        let flashFired: Bool?
        let whiteBalance: Int?
        let latitude: Double?
        let longitude: Double?
        let altitude: Double?

        var dictionaryRepresentation: [String: Any] {
            var dict: [String: Any] = [:]
            if let make = make { dict["Make"] = make }
            if let model = model { dict["Model"] = model }
            if let dateTime = dateTime { dict["DateTime"] = dateTime }
            if let orientation = orientation { dict["Orientation"] = orientation }
            if let exposureTime = exposureTime { dict["ExposureTime"] = exposureTime }
            if let fNumber = fNumber { dict["FNumber"] = fNumber }
            if let isoSpeedRatings = isoSpeedRatings { dict["ISOSpeedRatings"] = isoSpeedRatings }
            if let focalLength = focalLength { dict["FocalLength"] = focalLength }
            if let focusDistance = focusDistance { dict["FocusDistance"] = focusDistance }
            if let lensModel = lensModel { dict["LensModel"] = lensModel }
            if let brightnessValue = brightnessValue { dict["BrightnessValue"] = brightnessValue }
            if let exposureBiasValue = exposureBiasValue { dict["ExposureBiasValue"] = exposureBiasValue }
            if let meteringMode = meteringMode { dict["MeteringMode"] = meteringMode }
            if let flashFired = flashFired { dict["Flash"] = flashFired }
            if let whiteBalance = whiteBalance { dict["WhiteBalance"] = whiteBalance }
            if let latitude = latitude { dict["GPSLatitude"] = latitude }
            if let longitude = longitude { dict["GPSLongitude"] = longitude }
            if let altitude = altitude { dict["GPSAltitude"] = altitude }
            return dict
        }
    }

    struct IPTCData {
        let keywords: [String]?
        let caption: String?
        let copyright: String?
        let creator: String?
        let title: String?
        let location: String?
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Extract all metadata from image data
    func extractMetadata(from imageData: Data) async throws -> ImageMetadata {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            throw MetadataError.invalidImage
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] ?? [:]

        let exifData = parseEXIFData(from: properties)
        let iptcData = parseIPTCData(from: properties)

        let metadata = ImageMetadata(exif: exifData, iptc: iptcData, raw: properties)

        logger.info("Metadata extracted successfully")
        return metadata
    }

    /// Extract EXIF data from image data
    func extractEXIFData(from imageData: Data) async throws -> EXIFData {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            throw MetadataError.invalidImage
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] ?? [:]

        guard let exifData = parseEXIFData(from: properties) else {
            throw MetadataError.metadataNotAvailable
        }

        logger.info("EXIF data extracted")
        return exifData
    }

    /// Extract metadata from video asset
    func extractVideoMetadata(from asset: AVAsset) async throws -> VideoMetadata {
        let duration = asset.duration
        let tracks = asset.tracks

        var videoTrackInfo: VideoTrackInfo?
        var audioTrackInfo: AudioTrackInfo?

        for track in tracks {
            if track.mediaType == .video {
                videoTrackInfo = extractVideoTrackInfo(from: track)
            } else if track.mediaType == .audio {
                audioTrackInfo = extractAudioTrackInfo(from: track)
            }
        }

        let commonMetadata = CMTimeGetSeconds(duration)

        return VideoMetadata(
            duration: duration,
            videoTrackInfo: videoTrackInfo,
            audioTrackInfo: audioTrackInfo,
            commonMetadata: commonMetadata
        )
    }

    /// Get camera device information
    func getCameraDeviceInfo(from metadata: [String: Any]) -> CameraDeviceInfo? {
        let exifDict = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any]

        let make = exifDict?[kCGImagePropertyExifCameraMake as String] as? String
        let model = exifDict?[kCGImagePropertyExifCameraModel as String] as? String
        let lensModel = exifDict?[kCGImagePropertyExifLensModel as String] as? String

        guard make != nil || model != nil else {
            return nil
        }

        return CameraDeviceInfo(make: make, model: model, lensModel: lensModel)
    }

    // MARK: - Private Methods

    private func parseEXIFData(from properties: [String: Any]) -> EXIFData? {
        guard let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] else {
            return nil
        }

        let make = exifDict[kCGImagePropertyExifCameraMake as String] as? String
        let model = exifDict[kCGImagePropertyExifCameraModel as String] as? String
        let orientation = exifDict[kCGImagePropertyExifOrientation as String] as? Int
        let exposureTime = exifDict[kCGImagePropertyExifExposureTime as String] as? Double
        let fNumber = exifDict[kCGImagePropertyExifFNumber as String] as? Double
        let isoSpeedRatings = exifDict[kCGImagePropertyExifISOSpeedRatings as String] as? [Int]
        let focalLength = exifDict[kCGImagePropertyExifFocalLength as String] as? Double
        let lensModel = exifDict[kCGImagePropertyExifLensModel as String] as? String
        let brightnessValue = exifDict[kCGImagePropertyExifBrightnessValue as String] as? Double
        let exposureBiasValue = exifDict[kCGImagePropertyExifExposureBiasValue as String] as? Double
        let meteringMode = exifDict[kCGImagePropertyExifMeteringMode as String] as? Int
        let whiteBalance = exifDict[kCGImagePropertyExifWhiteBalance as String] as? Int

        // Parse date
        var dateTime: Date?
        if let dateString = exifDict[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            dateTime = formatter.date(from: dateString)
        }

        // Parse GPS data
        var latitude: Double?
        var longitude: Double?
        var altitude: Double?

        if let gpsDict = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            latitude = gpsDict[kCGImagePropertyGPSLatitude as String] as? Double
            longitude = gpsDict[kCGImagePropertyGPSLongitude as String] as? Double
            altitude = gpsDict[kCGImagePropertyGPSAltitude as String] as? Double
        }

        // Parse focus distance
        var focusDistance: Double?
        if let auxDict = properties[kCGImagePropertyExifAuxDictionary as String] as? [String: Any] {
            focusDistance = auxDict[kCGImagePropertyExifAuxFocusDistance as String] as? Double
        }

        // Determine flash fired
        var flashFired: Bool?
        if let flashValue = exifDict[kCGImagePropertyExifFlash as String] as? Int {
            flashFired = (flashValue & 0x1) != 0
        }

        return EXIFData(
            make: make,
            model: model,
            dateTime: dateTime,
            orientation: orientation,
            exposureTime: exposureTime,
            fNumber: fNumber,
            isoSpeedRatings: isoSpeedRatings,
            focalLength: focalLength,
            focusDistance: focusDistance,
            lensModel: lensModel,
            brightnessValue: brightnessValue,
            exposureBiasValue: exposureBiasValue,
            meteringMode: meteringMode,
            flashFired: flashFired,
            whiteBalance: whiteBalance,
            latitude: latitude,
            longitude: longitude,
            altitude: altitude
        )
    }

    private func parseIPTCData(from properties: [String: Any]) -> IPTCData? {
        guard let iptcDict = properties[kCGImagePropertyIPTCDictionary as String] as? [String: Any] else {
            return nil
        }

        let keywords = iptcDict[kCGImagePropertyIPTCKeywords as String] as? [String]
        let caption = iptcDict[kCGImagePropertyIPTCCaptionAbstract as String] as? String
        let copyright = iptcDict[kCGImagePropertyIPTCCopyrightNotice as String] as? String
        let creator = iptcDict[kCGImagePropertyIPTCCredit as String] as? String
        let title = iptcDict[kCGImagePropertyIPTCObjectName as String] as? String
        let location = iptcDict[kCGImagePropertyIPTCLocationCreated as String] as? String

        return IPTCData(
            keywords: keywords,
            caption: caption,
            copyright: copyright,
            creator: creator,
            title: title,
            location: location
        )
    }

    private func extractVideoTrackInfo(from track: AVAssetTrack) -> VideoTrackInfo {
        let naturalSize = track.naturalSize
        let frameRate = track.nominalFrameRate
        let bitRate = track.estimatedDataRate
        let duration = track.timeRange.duration

        return VideoTrackInfo(
            naturalSize: naturalSize,
            frameRate: frameRate,
            bitRate: bitRate,
            duration: duration
        )
    }

    private func extractAudioTrackInfo(from track: AVAssetTrack) -> AudioTrackInfo {
        let bitRate = track.estimatedDataRate
        let duration = track.timeRange.duration
        let channels = track.formatDescriptions.count

        return AudioTrackInfo(
            bitRate: bitRate,
            duration: duration,
            channelCount: channels
        )
    }
}

struct VideoMetadata {
    let duration: CMTime
    let videoTrackInfo: VideoTrackInfo?
    let audioTrackInfo: AudioTrackInfo?
    let commonMetadata: Double
}

struct VideoTrackInfo {
    let naturalSize: CGSize
    let frameRate: Float
    let bitRate: Float
    let duration: CMTime
}

struct AudioTrackInfo {
    let bitRate: Float
    let duration: CMTime
    let channelCount: Int
}

struct CameraDeviceInfo {
    let make: String?
    let model: String?
    let lensModel: String?
}
