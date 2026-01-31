import AVFoundation
import os.log

/// Service for processing video (trim, compress, extract frames)
actor VideoProcessor {
    static let shared = VideoProcessor()

    private let logger = Logger(subsystem: "com.ai4science.camera", category: "VideoProcessor")

    enum VideoProcessingError: LocalizedError {
        case invalidAsset
        case exportFailed(String)
        case invalidTimeRange
        case frameExtractionFailed

        var errorDescription: String? {
            switch self {
            case .invalidAsset:
                return "Invalid video asset"
            case .exportFailed(let reason):
                return "Video export failed: \(reason)"
            case .invalidTimeRange:
                return "Invalid time range for trimming"
            case .frameExtractionFailed:
                return "Failed to extract frame from video"
            }
        }
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Trim video to specified time range
    func trimVideo(
        at url: URL,
        from startTime: CMTime,
        to endTime: CMTime,
        outputURL: URL
    ) async throws {
        let asset = AVAsset(url: url)

        // Validate time range
        guard startTime < endTime, endTime <= asset.duration else {
            throw VideoProcessingError.invalidTimeRange
        }

        return try await withCheckedThrowingContinuation { continuation in
            let composition = AVMutableComposition()

            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                continuation.resume(throwing: VideoProcessingError.invalidAsset)
                return
            }

            guard let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                continuation.resume(throwing: VideoProcessingError.invalidAsset)
                return
            }

            do {
                try compositionVideoTrack.insertTimeRange(
                    CMTimeRange(start: startTime, end: endTime),
                    of: videoTrack,
                    at: .zero
                )

                // Add audio track if available
                if let audioTrack = asset.tracks(withMediaType: .audio).first,
                   let compositionAudioTrack = composition.addMutableTrack(
                       withMediaType: .audio,
                       preferredTrackID: kCMPersistentTrackID_Invalid
                   ) {
                    try compositionAudioTrack.insertTimeRange(
                        CMTimeRange(start: startTime, end: endTime),
                        of: audioTrack,
                        at: .zero
                    )
                }

                try exportComposition(
                    composition,
                    to: outputURL,
                    completion: continuation
                )
            } catch {
                continuation.resume(throwing: VideoProcessingError.exportFailed(error.localizedDescription))
            }
        }
    }

    /// Compress video
    func compressVideo(
        at url: URL,
        outputURL: URL,
        preset: AVAssetExportPreset = .medium
    ) async throws {
        let asset = AVAsset(url: url)

        guard asset.isReadable else {
            throw VideoProcessingError.invalidAsset
        }

        return try await withCheckedThrowingContinuation { continuation in
            guard let exporter = AVAssetExportSession(asset: asset, presetName: preset) else {
                continuation.resume(throwing: VideoProcessingError.exportFailed("Cannot create export session"))
                return
            }

            exporter.outputURL = outputURL
            exporter.outputFileType = .mp4
            exporter.shouldOptimizeForNetworkUse = true

            exporter.exportAsynchronously {
                if exporter.status == .completed {
                    self.logger.info("Video compression completed")
                    continuation.resume()
                } else {
                    let error = exporter.error ?? NSError(domain: "VideoProcessing", code: -1)
                    self.logger.error("Video compression failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Extract a frame from video at specified time
    func extractFrame(
        from url: URL,
        at time: CMTime
    ) async throws -> UIImage {
        let asset = AVAsset(url: url)

        guard asset.isReadable else {
            throw VideoProcessingError.invalidAsset
        }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime.zero
        generator.requestedTimeToleranceAfter = CMTime.zero

        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            logger.info("Frame extracted at time: \(time.seconds)s")
            return image
        } catch {
            logger.error("Frame extraction failed: \(error.localizedDescription)")
            throw VideoProcessingError.frameExtractionFailed
        }
    }

    /// Extract frames at regular intervals
    func extractFrames(
        from url: URL,
        interval: CMTime,
        completion: @escaping (Result<[UIImage], Error>) -> Void
    ) {
        let asset = AVAsset(url: url)

        guard asset.isReadable else {
            completion(.failure(VideoProcessingError.invalidAsset))
            return
        }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        var frames: [UIImage] = []
        var currentTime = CMTime.zero
        let duration = asset.duration

        let times = NSMutableArray()
        while currentTime < duration {
            times.add(NSValue(time: currentTime))
            currentTime = CMTimeAdd(currentTime, interval)
        }

        generator.generateCGImagesAsynchronously(forTimes: times as! [NSValue]) { requestedTime, cgImage, actualTime, result, error in
            if let error = error {
                self.logger.error("Failed to generate frame: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let cgImage = cgImage {
                frames.append(UIImage(cgImage: cgImage))
            }

            if result == .finished {
                self.logger.info("Extracted \(frames.count) frames")
                completion(.success(frames))
            }
        }
    }

    /// Get video information
    func getVideoInfo(url: URL) async throws -> VideoInfo {
        let asset = AVAsset(url: url)

        guard asset.isReadable else {
            throw VideoProcessingError.invalidAsset
        }

        let duration = asset.duration
        let tracks = asset.tracks(withMediaType: .video)

        guard let videoTrack = tracks.first else {
            throw VideoProcessingError.invalidAsset
        }

        let size = videoTrack.naturalSize
        let frameRate = videoTrack.nominalFrameRate
        let bitRate = videoTrack.estimatedDataRate

        return VideoInfo(
            duration: duration,
            frameSize: size,
            frameRate: frameRate,
            bitRate: bitRate,
            fileSize: try getFileSize(url)
        )
    }

    // MARK: - Private Methods

    private func exportComposition(
        _ composition: AVMutableComposition,
        to outputURL: URL,
        completion: CheckedContinuation<Void, Error>
    ) throws {
        guard let exporter = AVAssetExportSession(asset: composition, presetName: .high) else {
            throw VideoProcessingError.exportFailed("Cannot create export session")
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = .mp4

        exporter.exportAsynchronously {
            if exporter.status == .completed {
                self.logger.info("Video trimming completed")
                completion.resume()
            } else {
                let error = exporter.error ?? NSError(domain: "VideoProcessing", code: -1)
                self.logger.error("Video export failed: \(error.localizedDescription)")
                completion.resume(throwing: error)
            }
        }
    }

    private func getFileSize(_ url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
}

struct VideoInfo {
    let duration: CMTime
    let frameSize: CGSize
    let frameRate: Float
    let bitRate: Float
    let fileSize: Int64

    var durationSeconds: Double {
        return duration.seconds
    }
}
