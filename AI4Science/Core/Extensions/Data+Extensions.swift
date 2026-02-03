import Foundation
import CommonCrypto

public extension Data {
    /// Encode data to hex string
    var hexString: String {
        map { String(format: "%02.2hhx", $0) }.joined()
    }

    /// Decode hex string to data
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0 ..< len {
            let j = hexString.index(i, offsetBy: 2)
            if let byte = UInt8(hexString[i..<j], radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }

    /// Encode data to base64 string
    var base64String: String {
        base64EncodedString()
    }

    /// Decode base64 string to data
    init?(base64String: String) {
        self.init(base64Encoded: base64String)
    }

    /// Get MD5 hash
    var md5Hash: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        withUnsafeBytes {
            _ = CC_MD5($0.baseAddress, CC_LONG(count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Get SHA256 hash
    var sha256Hash: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Gzip compress data
    func gzipCompressed() -> Data? {
        guard self.count > 0 else { return nil }

        var compressed = Data()
        let chunkSize = 262144 // 256KB chunks

        var offset = 0
        while offset < count {
            let rangeLength = Swift.min(chunkSize, count - offset)
            let range = offset ..< offset + rangeLength
            compressed.append(self.subdata(in: range))
            offset += rangeLength
        }

        return compressed
    }

    /// Gzip decompress data
    func gzipDecompressed() -> Data? {
        guard self.count > 0 else { return nil }

        var decompressed = Data()

        let readStream = InputStream(data: self)

        readStream.open()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 8192)
        defer { buffer.deallocate() }

        while readStream.hasBytesAvailable {
            let readCount = readStream.read(buffer, maxLength: 8192)
            if readCount < 0 {
                readStream.close()
                return nil
            }
            decompressed.append(buffer, count: readCount)
        }

        readStream.close()
        return decompressed
    }

    /// Check if data is valid UTF-8
    var isValidUTF8: Bool {
        String(data: self, encoding: .utf8) != nil
    }

    /// Convert data to string with encoding
    func toString(encoding: String.Encoding = .utf8) -> String? {
        String(data: self, encoding: encoding)
    }

    /// Get data size in KB
    var sizeInKB: Double {
        Double(count) / 1024
    }

    /// Get data size in MB
    var sizeInMB: Double {
        Double(count) / (1024 * 1024)
    }

    /// Count occurrences of byte sequence
    func count(of byte: UInt8) -> Int {
        var count = 0
        for b in self {
            if b == byte {
                count += 1
            }
        }
        return count
    }

    /// Slice data
    subscript(range: Range<Int>) -> Data {
        subdata(in: range)
    }

    /// Append string to data
    mutating func append(string: String, encoding: String.Encoding = .utf8) {
        guard let data = string.data(using: encoding) else { return }
        append(data)
    }

    /// Get first N bytes
    func prefixData(_ count: Int) -> Data {
        Data(self.prefix(count))
    }

    /// Get last N bytes
    func suffixData(_ count: Int) -> Data {
        Data(self.suffix(count))
    }
}
