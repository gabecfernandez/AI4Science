import Foundation

extension Date {
    /// Format date to ISO 8601 string
    public func toISO8601String() -> String {
        ISO8601DateFormatter().string(from: self)
    }

    /// Format date to readable string
    public func toFormattedString(format: String = "MMM dd, yyyy") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    /// Format date and time
    public func toFormattedDateTime(format: String = "MMM dd, yyyy 'at' HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    /// Get relative time string (e.g., "2 hours ago")
    public func toRelativeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Format as time only
    public func toTimeString(format: String = "HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    /// Parse ISO 8601 string
    public static func fromISO8601String(_ string: String) -> Date? {
        ISO8601DateFormatter().date(from: string)
    }

    /// Get date components
    public func components(_ components: Set<Calendar.Component>) -> DateComponents {
        Calendar.current.dateComponents(components, from: self)
    }

    /// Check if date is today
    public var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if date is tomorrow
    public var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Check if date is yesterday
    public var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Start of day
    public var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of day
    public var endOfDay: Date {
        let components = DateComponents(day: 1, second: -1)
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Number of days since date
    public func daysSince(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: self)
        return components.day ?? 0
    }
}
