import Foundation

public extension Date {
    /// Format date using ISO8601 format
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }

    /// Get date as string with custom format
    func formatted(as format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    /// Get date as string with style
    func formatted(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }

    /// Get relative time string (e.g., "2 hours ago")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Get short relative time string (e.g., "2h ago")
    var shortRelativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Check if date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Get start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Get end of day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Add days to date
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Add hours to date
    func addingHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    /// Add minutes to date
    func addingMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    /// Get component of date
    func component(_ component: Calendar.Component) -> Int {
        Calendar.current.component(component, from: self)
    }

    /// Get year
    var year: Int {
        component(.year)
    }

    /// Get month
    var month: Int {
        component(.month)
    }

    /// Get day
    var day: Int {
        component(.day)
    }

    /// Get hour
    var hour: Int {
        component(.hour)
    }

    /// Get minute
    var minute: Int {
        component(.minute)
    }

    /// Get second
    var second: Int {
        component(.second)
    }

    /// Get weekday (1 = Sunday, 7 = Saturday)
    var weekday: Int {
        component(.weekday)
    }

    /// Get time interval in seconds since date
    func timeIntervalSince(_ date: Date) -> TimeInterval {
        timeIntervalSince(date)
    }

    /// Check if date is within time interval
    func isWithin(_ interval: TimeInterval, of date: Date) -> Bool {
        abs(timeIntervalSince(date)) <= interval
    }
}
