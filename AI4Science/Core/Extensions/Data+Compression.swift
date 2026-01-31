import Foundation
import Compression

extension Data {
    /// Compress data using COMPRESSION_ZSTD algorithm
    public func compressed() throws -> Data {
        guard count > 0 else { return self }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        defer { buffer.deallocate() }

        let compressedSize = withUnsafeBytes { inputBytes in
            compression_encode_buffer(
                buffer,
                count,
                inputBytes.baseAddress?.assumingMemoryBound(to: UInt8.self) ?? buffer,
                count,
                nil,
                COMPRESSION_ZSTD
            )
        }

        guard compressedSize > 0 else {
            throw CompressionError.compressionFailed
        }

        return Data(bytes: buffer, count: compressedSize)
    }

    /// Decompress data
    public func decompressed() throws -> Data {
        guard count > 0 else { return self }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count * 2)
        defer { buffer.deallocate() }

        let decompressedSize = withUnsafeBytes { inputBytes in
            compression_decode_buffer(
                buffer,
                count * 2,
                inputBytes.baseAddress?.assumingMemoryBound(to: UInt8.self) ?? buffer,
                count,
                nil,
                COMPRESSION_ZSTD
            )
        }

        guard decompressedSize > 0 else {
            throw CompressionError.decompressionFailed
        }

        return Data(bytes: buffer, count: decompressedSize)
    }

    /// Get compression ratio
    public func compressionRatio() throws -> Double {
        let compressed = try compressed()
        return Double(compressed.count) / Double(count)
    }

    /// Check if data is likely compressed
    public var isLikelyCompressed: Bool {
        guard count >= 4 else { return false }
        // Check for common compression signatures
        let bytes = [UInt8](self.prefix(4))
        return (bytes[0] == 0x28 && bytes[1] == 0xB5 && bytes[2] == 0x2F && bytes[3] == 0xFD) || // zstd
               (bytes[0] == 0x1F && bytes[1] == 0x8B) || // gzip
               (bytes[0] == 0x78 && (bytes[1] == 0x01 || bytes[1] == 0x5E || bytes[1] == 0x9C || bytes[1] == 0xDA)) // deflate/zlib
    }
}

enum CompressionError: LocalizedError, Sendable {
    case compressionFailed
    case decompressionFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress data"
        case .decompressionFailed:
            return "Failed to decompress data"
        }
    }
}
