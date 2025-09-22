import Foundation

// MARK: - Date Formatting Extensions
extension DateFormatter {
    
    /// Formats date to show day of week (e.g., "Wed")
    static func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    /// Formats date with day and full date (e.g., "Wed 05-09-2025")
    static func dayWithDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd-MM-yyyy"
        return formatter.string(from: date)
    }
    
    /// Formats date for user-friendly display (e.g., "05 Sep, 2025")
    static func displayFormat(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, yyyy"
        return formatter.string(from: date)
    }
    
    /// Parses date from full format string
    static func parseFromFullFormat(_ fullFormat: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd-MM-yyyy"
        return formatter.date(from: fullFormat)
    }
    
    /// Extracts day name from full format string (e.g., "Wed" from "Wed 05-09-2025")
    static func extractDayFromFullFormat(_ fullFormat: String) -> String {
        return String(fullFormat.prefix(3))
    }
}
