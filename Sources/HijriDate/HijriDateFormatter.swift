import Foundation

/// A formatter that converts between Hijri dates and their textual representations.
///
/// HijriDateFormatter is designed to be similar to Foundation's DateFormatter but specifically
/// for the Hijri calendar system. It provides functionality for formatting Hijri dates as strings
/// and parsing strings as Hijri dates.
public class HijriDateFormatter {

    // MARK: - Properties

    /// The calendar to use for date calculations.
    public var calendar: HijriCalendar

    /// The locale to use for formatting.
    public var locale: Locale

    /// The date format style to use for formatting.
    public var dateStyle: DateFormatter.Style = .medium

    /// A custom date format string to use for formatting.
    public var dateFormat: String?

    /// The language to use for month names and other localized strings.
    public var language: HijriLanguage = .english

    // MARK: - Initialization

    /// Creates a new HijriDateFormatter with the default calendar and locale.
    public init() {
        self.calendar = HijriCalendar.default
        self.locale = Locale.current
    }

    /// Creates a new HijriDateFormatter with the specified calendar and locale.
    ///
    /// - Parameters:
    ///   - calendar: The calendar to use for date calculations.
    ///   - locale: The locale to use for formatting.
    public init(calendar: HijriCalendar, locale: Locale = Locale.current) {
        self.calendar = calendar
        self.locale = locale
    }

    // MARK: - Formatting Methods

    /// Formats a Hijri date as a string.
    ///
    /// - Parameter date: The Hijri date to format.
    /// - Returns: A string representation of the Hijri date.
    public func string(from date: HijriDate) throws -> String {
        if let dateFormat = dateFormat {
            return try formatDate(date, withFormat: dateFormat)
        }

        // Use the date style if no custom format is specified
        switch dateStyle {
        case .none:
            return ""
        case .short:
            return try formatDate(date, withFormat: "d/M/y")
        case .medium:
            return try formatDate(date, withFormat: "d MMM y")
        case .long:
            return try formatDate(date, withFormat: "d MMMM y")
        case .full:
            return try formatDate(date, withFormat: "EEEE, d MMMM y")
        @unknown default:
            return try formatDate(date, withFormat: "d MMM y")
        }
    }

    /// Parses a string as a Hijri date.
    ///
    /// - Parameter string: The string to parse.
    /// - Returns: A Hijri date, or nil if the string could not be parsed.
    public func date(from string: String) -> HijriDate? {
        // This is a simplified implementation that only handles a few common formats

        // Try to parse as "d/M/y"
        let shortFormat = #"(\d{1,2})/(\d{1,2})/(\d{4})"#
        if let match = string.range(of: shortFormat, options: .regularExpression) {
            let components = string[match].split(separator: "/")
            if components.count == 3,
                let day = Int(components[0]),
                let month = Int(components[1]),
                let year = Int(components[2])
            {
                return HijriDate(year: year, month: month, day: day)
            }
        }

        // Try to parse as "d MMM y" or "d MMMM y"
        let mediumFormat = #"(\d{1,2}) ([A-Za-z]+) (\d{4})"#
        if let match = string.range(of: mediumFormat, options: .regularExpression) {
            let components = string[match].split(separator: " ")
            if components.count == 3,
                let day = Int(components[0]),
                let year = Int(components[2])
            {
                let monthName = String(components[1])
                if let month = monthNumber(from: monthName) {
                    return HijriDate(year: year, month: month, day: day)
                }
            }
        }

        return nil
    }

    // MARK: - Helper Methods

    /// Formats a Hijri date using the specified format string.
    ///
    /// - Parameters:
    ///   - date: The Hijri date to format.
    ///   - format: The format string to use.
    /// - Returns: A string representation of the Hijri date.
    private func formatDate(_ date: HijriDate, withFormat format: String) throws -> String {
        var result = ""
        var isEscaped = false
        var i = 0

        while i < format.count {
            let currentIndex = format.index(format.startIndex, offsetBy: i)
            let currentChar = format[currentIndex]

            if isEscaped {
                result.append(currentChar)
                isEscaped = false
                i += 1
                continue
            }

            if currentChar == "'" {
                isEscaped = true
                i += 1
                continue
            }

            // Count consecutive occurrences of the current character
            var count = 1
            var nextIndex = format.index(after: currentIndex)
            while nextIndex < format.endIndex && format[nextIndex] == currentChar {
                count += 1
                nextIndex = format.index(after: nextIndex)
            }

            // Handle format patterns based on character and count
            switch currentChar {
            case "d":
                if count >= 2 {
                    // Day of month with leading zero (01-30)
                    result.append(String(format: "%02d", date.day))
                } else {
                    // Day of month (1-30)
                    result.append(String(date.day))
                }
            case "M":
                if count == 1 {
                    // Month (1-12)
                    result.append(String(date.month))
                } else if count == 2 {
                    // Month with leading zero (01-12)
                    result.append(String(format: "%02d", date.month))
                } else if count == 3 {
                    // Three-character month name (MMM)
                    result.append(shortMonthName(for: date.month))
                } else if count >= 4 {
                    // Full month name (MMMM)
                    result.append(fullMonthName(for: date.month))
                }
            case "y":
                if count == 1 || count == 2 {
                    // Always use full 4-digit year for 'y' and 'yy' for consistency
                    result.append(String(date.year))
                } else if count == 3 || count >= 4 {
                    // Full year (already 4 digits)
                    result.append(String(date.year))
                }
            case "E":
                if count <= 3 {
                    // Short weekday name (E, EE, EEE)
                    let weekday = try weekdayFromHijriDate(date)
                    result.append(shortWeekdayName(for: weekday))
                } else {
                    // Full weekday name (EEEE)
                    let weekday = try weekdayFromHijriDate(date)
                    result.append(fullWeekdayName(for: weekday))
                }
            default:
                // Append any other character as-is
                result.append(currentChar)
            }

            // Skip past all the characters we've processed
            i += count
        }

        return result
    }

    /// Gets the weekday (1-7) for a Hijri date.
    ///
    /// - Parameter date: The Hijri date.
    /// - Returns: The weekday (1 = Sunday, 7 = Saturday).
    private func weekdayFromHijriDate(_ date: HijriDate) throws -> Int {
        let gregorianDate = try calendar.date(from: date)
        let calendar = Calendar(identifier: .gregorian)
        let weekday = calendar.component(.weekday, from: gregorianDate)
        return weekday
    }

    /// Gets the short name for a month.
    ///
    /// - Parameter month: The month number (1-12).
    /// - Returns: The short name for the month.
    private func shortMonthName(for month: Int) -> String {
        switch language {
        case .english:
            return englishShortMonthNames[month - 1]
        case .arabic:
            return arabicMonthNames[month - 1]
        }
    }

    /// Gets the full name for a month.
    ///
    /// - Parameter month: The month number (1-12).
    /// - Returns: The full name for the month.
    private func fullMonthName(for month: Int) -> String {
        switch language {
        case .english:
            return englishFullMonthNames[month - 1]
        case .arabic:
            return arabicMonthNames[month - 1]
        }
    }

    /// Gets the short name for a weekday.
    ///
    /// - Parameter weekday: The weekday number (1-7).
    /// - Returns: The short name for the weekday.
    private func shortWeekdayName(for weekday: Int) -> String {
        switch language {
        case .english:
            return englishShortWeekdayNames[weekday - 1]
        case .arabic:
            return arabicShortWeekdayNames[weekday - 1]
        }
    }

    /// Gets the full name for a weekday.
    ///
    /// - Parameter weekday: The weekday number (1-7).
    /// - Returns: The full name for the weekday.
    private func fullWeekdayName(for weekday: Int) -> String {
        switch language {
        case .english:
            return englishFullWeekdayNames[weekday - 1]
        case .arabic:
            return arabicFullWeekdayNames[weekday - 1]
        }
    }

    /// Gets the month number for a month name.
    ///
    /// - Parameter name: The month name.
    /// - Returns: The month number (1-12), or nil if the name is not recognized.
    private func monthNumber(from name: String) -> Int? {
        switch language {
        case .english:
            if let index = englishFullMonthNames.firstIndex(of: name) {
                return index + 1
            }
            if let index = englishShortMonthNames.firstIndex(of: name) {
                return index + 1
            }
        case .arabic:
            if let index = arabicMonthNames.firstIndex(of: name) {
                return index + 1
            }
        }

        return nil
    }

    // MARK: - Localized Month and Weekday Names

    /// The English short month names.
    private let englishShortMonthNames = [
        "Muh", "Saf", "Rb1", "Rb2", "Jm1", "Jm2", "Raj", "Sha", "Ram", "Shw", "Qid", "Hij",
    ]

    /// The English full month names.
    private let englishFullMonthNames = [
        "Muharram", "Safar", "Rabi Al Awwal", "Rabi Al Thani", "Jumada Al Oula", "Jumada Al Akhira",
        "Rajab", "Shaban", "Ramadan", "Shawwal", "Dhul Qidah", "Dhul Hijjah",
    ]

    /// The Arabic month names.
    private let arabicMonthNames = [
        "محرم", "صفر", "ربيع الأول", "ربيع الثاني", "جمادى الأولى", "جمادى الآخرة",
        "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة",
    ]

    /// The English short weekday names.
    private let englishShortWeekdayNames = [
        "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat",
    ]

    /// The English full weekday names.
    private let englishFullWeekdayNames = [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
    ]

    /// The Arabic short weekday names.
    private let arabicShortWeekdayNames = [
        "أحد", "إثن", "ثلا", "أرب", "خمي", "جمع", "سبت",
    ]

    /// The Arabic full weekday names.
    private let arabicFullWeekdayNames = [
        "الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت",
    ]
}

/// The language to use for month names and other localized strings.
public enum HijriLanguage {
    /// English language.
    case english

    /// Arabic language.
    case arabic
}
