import Foundation

extension String {
    /// Check if string is a valid email
    public var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }

    /// Check if string is a valid URL
    public var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return URLComponents(url: url, resolvingAgainstBaseURL: true)?.scheme != nil
    }

    /// Check if string is empty or whitespace only
    public var isBlank: Bool {
        trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Check if string is not empty
    public var isNotEmpty: Bool {
        !isEmpty
    }

    /// Trim whitespace and newlines
    public var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Check if string contains only letters
    public var isAlpha: Bool {
        !isEmpty && allSatisfy { $0.isLetter }
    }

    /// Check if string contains only numbers
    public var isNumeric: Bool {
        !isEmpty && allSatisfy { $0.isNumber }
    }

    /// Check if string contains only alphanumeric characters
    public var isAlphanumeric: Bool {
        !isEmpty && allSatisfy { $0.isLetter || $0.isNumber }
    }

    /// Capitalize first letter
    public var capitalizedFirst: String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }

    /// Reverse string
    public var reversed: String {
        String(reversed())
    }

    /// Remove whitespace
    public var removingWhitespace: String {
        filter { !$0.isWhitespace }
    }

    /// Truncate to maximum length
    public func truncated(to length: Int, trailing: String = "...") -> String {
        guard count > length else { return self }
        let index = index(startIndex, offsetBy: length - trailing.count)
        return String(self[..<index]) + trailing
    }

    /// Check minimum length
    public func hasMinimumLength(_ length: Int) -> Bool {
        count >= length
    }

    /// Check maximum length
    public func hasMaximumLength(_ length: Int) -> Bool {
        count <= length
    }

    /// Check if contains substring
    public func containsIgnoringCase(_ substring: String) -> Bool {
        lowercased().contains(substring.lowercased())
    }
}
