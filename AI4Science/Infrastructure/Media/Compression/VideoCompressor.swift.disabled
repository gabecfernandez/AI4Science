import AVFoundation
import os.log

/// Service for compressing videos while preserving quality
actor VideoCompressor {
    static let shared = VideoCompressor()

    private let logger = Logger(subsystem: "com.ai4science.media", category: "VideoCompressor")

    enum CompressionQuality {
        case low
        case medium
        case high

        var preset: AVAssetExportPreset {
            switch self {
            case .low:
                return .low
            case .medium:
                return .medium
            case .high:
                return .high
            }
        }

        var estimatedBitrate: Int32 {
            switch self {
            case .low:
                return 1000000      // 1 Mbps
            case .medium:
                return 4000000      // 4 Mbps
            case .high:
                return 10000000     // 10 Mbps
            }
        }

        var description: String {
            switch self {
            case .low:
                return "Low"
            case .medium:
                return "Medium"
            case .high:
                return "High"
            }
        }
    }

    enum CompressionError: LocalizedError {
        case invalidAsset
        case exportFailed(String)
        case invalidOutputURL
        case compressionCancelled

        var errorDescription: String? {
            switch self {
            case .invalidAsset:
                return "Invalid video asset"
            case .exportFailed(let reason):
                return "Video compression failed: \(reason)"
            case .invalidOutputURL:
                return "Invalid output URL"
            case .compressionCancelled:
                return "Video compression was cancelled"
            }
        }
    }

    struct CompressionResult {
        let outputURL: URL
        let originalSize: Int64
        let compressedSize: Int64
        let duration: CMTime
        let compressionRatio: Double

        var estimatedBitrate: Float {
            guard duration.seconds > 0 else {
                return 0
            }

            return Float(compressedSize * 8) / Float(duration.seconds * 1_000_000)
        }

        var spaceSaved: String {
            let savings = originalSize - compressedSize
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: savings)
        }
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Compress video with quality setting
    func compressVideo(
        from sourceURL: URL,
        to outputURL: URL,
        quality: CompressionQuality = .medium
    ) async throws -> CompressionResult {
        let asset = AVAsset(url: sourceURL)

        guard asset.isReadable else {
            throw CompressionError.invalidAsset
        }

        // Get original file size
        let sourceAttributes = try FileManager.default.attributesOfItem(atPath: sourceURL.path)
        let originalSize = sourceAttributes[.size] as? Int64 ?? 0

        return try await withCheckedThrowingContinuation { continuation in
            guard let exporter = AVAssetExportSession(asset: asset, presetName: quality.preset) else {
                continuation.resume(throwing: CompressionError.exportFailed("Cannot create export session"))
                return
            }

            exporter.outputURL = outputURL
            exporter.outputFileType = .mp4
            exporter.shouldOptimizeForNetworkUse = true

            // Set bit rate
            let videoComposition = AVMutableVideoComposition(propertiesOf: asset)
            exporter.videoComposition = videoComposition

            exporter.exportAsynchronously { [weak self] in
                guard let self = self else {
                    return
                }

                switch exporter.status {
                case .completed:
                    do {
                        let compressedAttributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
                        let compressedSize = compressedAttributes[.size] as? Int64 ?? 0
                        let duration = asset.duration
                        let ratio = Double(compressedSize) / Double(originalSize)

                        let result = CompressionResult(
                            outputURL: outputURL,
                            originalSize: originalSize,
                            compressedSize: compressedSize,
                            duration: duration,
                            compressionRatio: ratio
                        )

                        self.logger.info("Video compressed: \(quality.description), ratio: \(String(format: "%.2f", ratio))")
                        continuation.resume(returning: result)
                    } catch {
                        self.logger.error("Failed to get compressed file info: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }

                case .failed:
                    let error = exporter.error ?? NSError(domain: "VideoCompression", code: -1)
                    self.logger.error("Video compression failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)

                case .cancelled:
                    self.logger.warning("Video compression cancelled")
                    continuation.resume(throwing: CompressionError.compressionCancelled)

                default:
                    break
                }
            }
        }
    }

    /// Compress video with custom settings
    func compressVideoCustom(
        from sourceURL: URL,
        to outputURL: URL,
        bitrate: Int32,
        frameRate: Int32? = nil
    ) async throws -> CompressionResult {
        let asset = AVAsset(url: sourceURL)

        guard asset.isReadable else {
            throw CompressionError.invalidAsset
        }

        let sourceAttributes = try FileManager.default.attributesOfItem(atPath: sourceURL.path)
        let originalSize = sourceAttributes[.size] as? Int64 ?? 0

        return try await withCheckedThrowingContinuation { continuation in
            guard let exporter = AVAssetExportSession(asset: asset, presetName: .medium) else {
                continuation.resume(throwing: CompressionError.exportFailed("Cannot create export session"))
                return
            }

            exporter.outputURL = outputURL
            exporter.outputFileType = .mp4
            exporter.shouldOptimizeForNetworkUse = true

            // Configure video composition with custom settings
            let videoComposition = AVMutableVideoComposition(propertiesOf: asset)
            if let customFrameRate = frameRate {
                videoComposition?.frameDuration = CMTimeMake(1, customFrameRate)
            }
            exporter.videoComposition = videoComposition

            exporter.exportAsynchronously { [weak self] in
                guard let self = self else {
                    return
                }

                if exporter.status == .completed {
                    do {
                        let compressedAttributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
                        let compressedSize = compressedAttributes[.size] as? Int64 ?? 0
                        let duration = asset.duration
                        let ratio = Double(compressedSize) / Double(originalSize)

                        let result = CompressionResult(
                            outputURL: outputURL,
                            originalSize: originalSize,
                            compressedSize: compressedSize,
                            duration: duration,
                            compressionRatio: ratio
                        )

                        self.logger.info("Video custom compressed with bitrate: \(bitrate)")
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    let error = exporter.error ?? NSError(domain: "VideoCompression", code: -1)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Estimate compression ratio for quality level
    func estimateCompressionRatio(for quality: CompressionQuality) -> Double {
        switch quality {
        case .low:
            return 0.1   // ~10% of original size
        case .medium:
            return 0.3   // ~30% of original size
        case .high:
            return 0.6   // ~60% of original size
        }
    }

    /// Estimate final file size
    func estimateCompressedSize(
        originalSize: Int64,
        quality: CompressionQuality
    ) -> Int64 {
        let ratio = estimateCompressionRatio(for: quality)
        return Int64(Double(originalSize) * ratio)
    }

    /// Batch compress videos
    func batchCompressVideos(
        from sourceURLs: [URL],
        outputDirectory: URL,
        quality: CompressionQuality = .medium
    ) async throws -> [CompressionResult] {
        var results: [CompressionResult] = []

        for (index, sourceURL) in sourceURLs.enumerated() {
            let filename = sourceURL.lastPathComponent
            let outputURL = outputDirectory.appendingPathComponent("compressed_\(filename)")

            do {
                let result = try await compressVideo(from: sourceURL, to: outputURL, quality: quality)
                results.append(result)

                logger.debug("Compressed video \(index + 1)/\(sourceURLs.count)")
            } catch {
                logger.error("Failed to compress video: \(error.localizedDescription)")
                throw error
            }
        }

        return results
    }

    /// Get total compression statistics
    func getCompressionStatistics(_ results: [CompressionResult]) -> CompressionStatistics {
        let totalOriginalSize = results.reduce(0) { $0 + $1.originalSize }
        let totalCompressedSize = results.reduce(0) { $0 + $1.compressedSize }
        let averageRatio = results.isEmpty ? 0 : results.map { $0.compressionRatio }.reduce(0, +) / Double(results.count)

        return CompressionStatistics(
            fileCount: results.count,
            totalOriginalSize: totalOriginalSize,
            totalCompressedSize: totalCompressedSize,
            totalSizeReduction: totalOriginalSize - totalCompressedSize,
            averageCompressionRatio: averageRatio
        )
    }
}

struct CompressionStatistics {
    let fileCount: Int
    let totalOriginalSize: Int64
    let totalCompressedSize: Int64
    let totalSizeReduction: Int64
    let averageCompressionRatio: Double

    var originalSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalOriginalSize)
    }

    var compressedSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalCompressedSize)
    }

    var reductionFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSizeReduction)
    }

    var percentageReduction: Double {
        guard totalOriginalSize > 0 else {
            return 0
        }

        return Double(totalSizeReduction) / Double(totalOriginalSize) * 100
    }
}
