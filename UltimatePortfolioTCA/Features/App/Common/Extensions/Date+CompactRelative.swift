import Foundation

extension Date {
    /// Returns a compact, human-readable string describing how long ago this date was
    /// relative to `now`.
    ///
    /// - Today: "< 1 hour" or "> N hours"
    /// - This week: "> N days"
    /// - This year: locale-aware day and month (e.g., "Feb 11" or "11.02")
    /// - Older: "> N years"
    func compactRelative(to now: Date = Date()) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .day, .year], from: self, to: now)
        let hours = components.hour ?? 0
        let days = components.day ?? 0
        let years = components.year ?? 0

        if years >= 1 {
            return "> \(years) \(years == 1 ? "year" : "years")"
        } else if days >= 7 {
            return formatted(.dateTime.day().month())
        } else if days >= 1 {
            return "> \(days) \(days == 1 ? "day" : "days")"
        } else if hours >= 1 {
            return "> \(hours) \(hours == 1 ? "hour" : "hours")"
        } else {
            return "< 1 hour"
        }
    }
}
