// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// A representation of a date in the Hijri (Islamic) calendar.
///
/// HijriDate is designed to be similar to Foundation's Date but specifically for the Hijri calendar.
/// It provides functionality for working with dates in the Hijri calendar system.
public struct HijriDate: Equatable, Hashable, Codable {
    /// The Hijri year component.
    public let year: Int

    /// The Hijri month component (1-12).
    public let month: Int

    /// The Hijri day component (1-30).
    public let day: Int

    /// Creates a new HijriDate with the specified components.
    ///
    /// - Parameters:
    ///   - year: The Hijri year.
    ///   - month: The Hijri month (1-12).
    ///   - day: The Hijri day (1-30).
    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// Creates a new HijriDate with validation of the specified components.
    ///
    /// - Parameters:
    ///   - year: The Hijri year.
    ///   - month: The Hijri month (1-12).
    ///   - day: The Hijri day (1-30).
    ///   - calendar: The HijriCalendar to use for validation (defaults to `HijriCalendar.default`).
    /// - Throws: `HijriDateError.invalidDateComponents` if the date is invalid.
    public init(validatedYear year: Int, month: Int, day: Int, calendar: HijriCalendar = .default) throws {
        // First check if the year is within the supported range for Umm al-Qura calendar
        if calendar.useUmmAlQura && (year < HijriCalendar.umStartYear || year > HijriCalendar.umEndYear) {
            throw HijriDateError.dateOutOfRange(details: "Year \(year) is outside the valid range (\(HijriCalendar.umStartYear)-\(HijriCalendar.umEndYear))")
        }

        // Then check if the date components are valid
        if !calendar.isValidHijriDate(year: year, month: month, day: day) {
            throw HijriDateError.invalidDateComponents(details: "Year: \(year), Month: \(month), Day: \(day) is not a valid Hijri date")
        }

        self.year = year
        self.month = month
        self.day = day
    }

    /// Creates a HijriDate from a Gregorian Date using the default HijriCalendar.
    ///
    /// - Parameter date: The Gregorian date to convert.
    /// - Returns: A HijriDate representing the same point in time in the Hijri calendar.
    /// - Throws: `HijriDateError` if the conversion fails.
    public init(from date: Date) throws {
        let hijriCalendar = HijriCalendar.default
        let components = hijriCalendar.hijriComponents(from: date)
        self.year = components.year
        self.month = components.month
        self.day = components.day
    }

    /// Creates a HijriDate from a Gregorian Date using the specified HijriCalendar.
    ///
    /// - Parameters:
    ///   - date: The Gregorian date to convert.
    ///   - calendar: The HijriCalendar to use for the conversion.
    /// - Returns: A HijriDate representing the same point in time in the Hijri calendar.
    /// - Throws: `HijriDateError` if the conversion fails.
    public init(from date: Date, calendar: HijriCalendar) throws {
        let components = calendar.hijriComponents(from: date)
        self.year = components.year
        self.month = components.month
        self.day = components.day
    }

    /// Checks if this HijriDate is valid according to the default HijriCalendar.
    ///
    /// - Returns: `true` if the date is valid, `false` otherwise.
    public var isValid: Bool {
        return HijriCalendar.default.isValidHijriDate(year: year, month: month, day: day)
    }

    /// Checks if this HijriDate is valid according to the specified HijriCalendar.
    ///
    /// - Parameter calendar: The HijriCalendar to use for validation.
    /// - Returns: `true` if the date is valid, `false` otherwise.
    public func isValid(in calendar: HijriCalendar) -> Bool {
        return calendar.isValidHijriDate(year: year, month: month, day: day)
    }

    /// Converts this HijriDate to a Gregorian Date using the default HijriCalendar.
    ///
    /// - Returns: A Date representing the same point in time in the Gregorian calendar.
    /// - Note: This method doesn't validate the date. Use `isValid` to check validity.
    public func toGregorianDate() -> Date {
        return HijriCalendar.default.date(from: self)
    }

    /// Converts this HijriDate to a Gregorian Date using the specified HijriCalendar.
    ///
    /// - Parameter calendar: The HijriCalendar to use for the conversion.
    /// - Returns: A Date representing the same point in time in the Gregorian calendar.
    /// - Note: This method doesn't validate the date. Use `isValid(in:)` to check validity.
    public func toGregorianDate(using calendar: HijriCalendar) -> Date {
        return calendar.date(from: self)
    }

    /// Converts this HijriDate to a Gregorian Date with validation using the default HijriCalendar.
    ///
    /// - Returns: A Date representing the same point in time in the Gregorian calendar.
    /// - Throws: `HijriDateError.invalidDateComponents` if the date is invalid.
    public func toValidatedGregorianDate() throws -> Date {
        if !isValid {
            throw HijriDateError.invalidDateComponents(details: "Year: \(year), Month: \(month), Day: \(day) is not a valid Hijri date")
        }
        return HijriCalendar.default.date(from: self)
    }

    /// Converts this HijriDate to a Gregorian Date with validation using the specified HijriCalendar.
    ///
    /// - Parameter calendar: The HijriCalendar to use for the conversion.
    /// - Returns: A Date representing the same point in time in the Gregorian calendar.
    /// - Throws: `HijriDateError.invalidDateComponents` if the date is invalid.
    public func toValidatedGregorianDate(using calendar: HijriCalendar) throws -> Date {
        if !isValid(in: calendar) {
            throw HijriDateError.invalidDateComponents(details: "Year: \(year), Month: \(month), Day: \(day) is not a valid Hijri date")
        }
        return calendar.date(from: self)
    }
}

// MARK: - CustomStringConvertible

extension HijriDate: CustomStringConvertible {
    public var description: String {
        return "\(year)-\(String(format: "%02d", month))-\(String(format: "%02d", day))"
    }
}

// MARK: - Comparable

extension HijriDate: Comparable {
    public static func < (lhs: HijriDate, rhs: HijriDate) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        if lhs.month != rhs.month {
            return lhs.month < rhs.month
        }
        return lhs.day < rhs.day
    }
}
