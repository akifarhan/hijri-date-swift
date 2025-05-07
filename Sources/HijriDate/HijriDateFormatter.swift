import Foundation
import ObjectiveC

/// A protocol defining the requirements for a localization provider.
///
/// This protocol allows custom localization providers to be created for different languages
/// and regions, providing month and weekday names for Hijri date formatting.
public protocol HijriLocalizationProvider {
    /// Get the short name for a month (1-12)
    func shortMonthName(for month: Int) -> String
    
    /// Get the full name for a month (1-12)
    func fullMonthName(for month: Int) -> String
    
    /// Get the short name for a weekday (1-7, where 1 is Sunday)
    func shortWeekdayName(for weekday: Int) -> String
    
    /// Get the full name for a weekday (1-7, where 1 is Sunday)
    func fullWeekdayName(for weekday: Int) -> String
    
    /// Get the locale identifier this provider is for
    var localeIdentifier: String { get }
}

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
    public var locale: Locale {
        didSet {
            // Update the localization provider when locale changes
            updateLocalizationProvider()
        }
    }

    /// The date format style to use for formatting.
    public var dateStyle: DateFormatter.Style = .medium

    /// A custom date format string to use for formatting.
    public var dateFormat: String?
    
    /// The localization provider to use for month and weekday names.
    private var localizationProvider: HijriLocalizationProvider

    // MARK: - Initialization

    /// Creates a new HijriDateFormatter with the default calendar and locale.
    public init() {
        self.calendar = HijriCalendar.default
        self.locale = Locale.current
        self.localizationProvider = HijriDateFormatter.findLocalizationProvider(for: locale)
    }

    /// Creates a new HijriDateFormatter with the specified calendar and locale.
    ///
    /// - Parameters:
    ///   - calendar: The calendar to use for date calculations.
    ///   - locale: The locale to use for formatting.
    public init(calendar: HijriCalendar, locale: Locale = Locale.current) {
        self.calendar = calendar
        self.locale = locale
        self.localizationProvider = HijriDateFormatter.findLocalizationProvider(for: locale)
    }
    
    /// Updates the localization provider based on the current locale.
    private func updateLocalizationProvider() {
        self.localizationProvider = HijriDateFormatter.findLocalizationProvider(for: locale)
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
        return localizationProvider.shortMonthName(for: month)
    }

    /// Gets the full name for a month.
    ///
    /// - Parameter month: The month number (1-12).
    /// - Returns: The full name for the month.
    private func fullMonthName(for month: Int) -> String {
        return localizationProvider.fullMonthName(for: month)
    }

    /// Gets the short name for a weekday.
    ///
    /// - Parameter weekday: The weekday number (1-7).
    /// - Returns: The short name for the weekday.
    private func shortWeekdayName(for weekday: Int) -> String {
        return localizationProvider.shortWeekdayName(for: weekday)
    }

    /// Gets the full name for a weekday.
    ///
    /// - Parameter weekday: The weekday number (1-7).
    /// - Returns: The full name for the weekday.
    private func fullWeekdayName(for weekday: Int) -> String {
        return localizationProvider.fullWeekdayName(for: weekday)
    }

    /// Gets the month number for a month name.
    ///
    /// - Parameter name: The month name.
    /// - Returns: The month number (1-12), or nil if the name is not recognized.
    private func monthNumber(from name: String) -> Int? {
        // Try to find month by its full name in the current localization provider
        for month in 1...12 {
            if localizationProvider.fullMonthName(for: month) == name || localizationProvider.shortMonthName(for: month) == name {
                return month
            }
        }
        
        // If not found in the current provider, check all registered providers
        let allProviders = HijriDateFormatter.getLocalizationProviders()
        
        for provider in allProviders {
            // Skip the current provider, we already checked it
            if provider.localeIdentifier == localizationProvider.localeIdentifier {
                continue
            }
            
            for month in 1...12 {
                if provider.fullMonthName(for: month) == name || provider.shortMonthName(for: month) == name {
                    return month
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Localization Provider Management
    
    /// A frozen, immutable class to coordinate access to providers with thread safety
    /// Using `@unchecked Sendable` because the class internally manages its own synchronization
    private final class ProvidersCoordinator: @unchecked Sendable {
        /// Singleton instance - fully thread-safe, established at compile time
        private static let _shared = ProvidersCoordinator()
        
        /// Thread-safe access to the singleton
        static var shared: ProvidersCoordinator {
            return _shared
        }
        
        /// Lock for thread-safe access
        private let lock = NSLock()
        
        /// Immutable default providers
        private let defaultProviders: [HijriLocalizationProvider] = [
            EnglishLocalizationProvider(),
            ArabicLocalizationProvider()
        ]
        
        /// Custom added providers
        private var customProviders: [HijriLocalizationProvider] = []
        
        /// Private initializer to ensure singleton pattern
        private init() {}
        
        /// Returns all providers (defaults + custom)
        func getAllProviders() -> [HijriLocalizationProvider] {
            lock.lock()
            defer { lock.unlock() }
            return defaultProviders + customProviders
        }
        
        /// Adds or updates a provider
        func registerProvider(_ provider: HijriLocalizationProvider) {
            lock.lock()
            defer { lock.unlock() }
            
            // Replace existing provider for the same locale if it exists
            if let index = customProviders.firstIndex(where: { $0.localeIdentifier == provider.localeIdentifier }) {
                customProviders[index] = provider
            } else {
                customProviders.append(provider)
            }
        }
        
        /// Finds appropriate provider for a locale
        func findProvider(for locale: Locale) -> HijriLocalizationProvider {
            lock.lock()
            defer { lock.unlock() }
            
            let allProviders = defaultProviders + customProviders
            
            // First check for exact match
            let identifier = locale.identifier
            if let provider = allProviders.first(where: { $0.localeIdentifier == identifier }) {
                return provider
            }
            
            // Then check for language match
            let language = locale.languageCode ?? "en"
            if let provider = allProviders.first(where: { $0.localeIdentifier.hasPrefix(language) }) {
                return provider
            }
            
            // Default to English
            return allProviders.first(where: { $0.localeIdentifier.hasPrefix("en") }) ?? EnglishLocalizationProvider()
        }
    }
    
    /// Get a copy of all registered localization providers
    private static func getLocalizationProviders() -> [HijriLocalizationProvider] {
        return ProvidersCoordinator.shared.getAllProviders()
    }
    
    /// Find a localization provider for the given locale
    private static func findLocalizationProvider(for locale: Locale) -> HijriLocalizationProvider {
        return ProvidersCoordinator.shared.findProvider(for: locale)
    }
    
    /// Registers a custom localization provider.
    /// - Parameter provider: The localization provider to register.
    public static func registerLocalizationProvider(_ provider: HijriLocalizationProvider) {
        // Thread-safety is handled within the coordinator class
        ProvidersCoordinator.shared.registerProvider(provider)
    }
}

// MARK: - Default Localization Providers

/// English localization provider for Hijri dates.
public struct EnglishLocalizationProvider: HijriLocalizationProvider {
    public var localeIdentifier: String { return "en" }
    
    /// The English short month names.
    private let shortMonthNames = [
        "Muh", "Saf", "Rb1", "Rb2", "Jm1", "Jm2", "Raj", "Sha", "Ram", "Shw", "Qid", "Hij",
    ]

    /// The English full month names.
    private let fullMonthNames = [
        "Muharram", "Safar", "Rabi Al Awwal", "Rabi Al Thani", "Jumada Al Oula", "Jumada Al Akhira",
        "Rajab", "Shaban", "Ramadan", "Shawwal", "Dhul Qidah", "Dhul Hijjah",
    ]

    /// The English short weekday names.
    private let shortWeekdayNames = [
        "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat",
    ]

    /// The English full weekday names.
    private let fullWeekdayNames = [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
    ]
    
    public func shortMonthName(for month: Int) -> String {
        guard month >= 1 && month <= 12 else { return "" }
        return shortMonthNames[month - 1]
    }
    
    public func fullMonthName(for month: Int) -> String {
        guard month >= 1 && month <= 12 else { return "" }
        return fullMonthNames[month - 1]
    }
    
    public func shortWeekdayName(for weekday: Int) -> String {
        guard weekday >= 1 && weekday <= 7 else { return "" }
        return shortWeekdayNames[weekday - 1]
    }
    
    public func fullWeekdayName(for weekday: Int) -> String {
        guard weekday >= 1 && weekday <= 7 else { return "" }
        return fullWeekdayNames[weekday - 1]
    }
    
    public init() {}
}

/// Arabic localization provider for Hijri dates.
public struct ArabicLocalizationProvider: HijriLocalizationProvider {
    public var localeIdentifier: String { return "ar" }
    
    /// The Arabic month names.
    private let monthNames = [
        "محرم", "صفر", "ربيع الأول", "ربيع الثاني", "جمادى الأولى", "جمادى الآخرة",
        "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة",
    ]
    
    /// The Arabic short weekday names.
    private let shortWeekdayNames = [
        "أحد", "إثن", "ثلا", "أرب", "خمي", "جمع", "سبت",
    ]

    /// The Arabic full weekday names.
    private let fullWeekdayNames = [
        "الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت",
    ]
    
    public func shortMonthName(for month: Int) -> String {
        guard month >= 1 && month <= 12 else { return "" }
        return monthNames[month - 1]
    }
    
    public func fullMonthName(for month: Int) -> String {
        guard month >= 1 && month <= 12 else { return "" }
        return monthNames[month - 1]
    }
    
    public func shortWeekdayName(for weekday: Int) -> String {
        guard weekday >= 1 && weekday <= 7 else { return "" }
        return shortWeekdayNames[weekday - 1]
    }
    
    public func fullWeekdayName(for weekday: Int) -> String {
        guard weekday >= 1 && weekday <= 7 else { return "" }
        return fullWeekdayNames[weekday - 1]
    }
    
    public init() {}
}
