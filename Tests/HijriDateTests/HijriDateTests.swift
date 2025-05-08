import Testing
@testable import HijriDate
import Foundation

// MARK: - HijriDate Core Functionality Tests

@Test func testHijriDateInitialization() throws {
    // Test direct initialization
    let date = HijriDate(year: 1445, month: 9, day: 1)
    #expect(date.year == 1445)
    #expect(date.month == 9)
    #expect(date.day == 1)

    // Test initialization from Gregorian date
    let gregorianDate = createDate(day: 11, month: 3, year: 2024) // Should be around 1 Ramadan 1445
    let hijriDate = try HijriDate(from: gregorianDate)

    // Verify the date is in the expected range
    #expect(hijriDate.year == 1445)
    #expect(hijriDate.month == 9)
    #expect(hijriDate.day >= 1 && hijriDate.day <= 3) // Allow for slight variations

    // Test initialization with specific calendar
    let calendar = HijriCalendar.default
    let hijriDateWithCalendar = try HijriDate(from: gregorianDate, calendar: calendar)
    #expect(hijriDateWithCalendar.year == hijriDate.year)
    #expect(hijriDateWithCalendar.month == hijriDate.month)
    #expect(hijriDateWithCalendar.day == hijriDate.day)
}

@Test func testHijriDateConversion() throws {
    // Create a HijriDate
    let hijriDate = HijriDate(year: 1445, month: 9, day: 1)

    // Convert to Gregorian
    let gregorianDate = hijriDate.toGregorianDate()

    // Convert back to Hijri
    let roundTripHijriDate = try HijriDate(from: gregorianDate)

    // Verify round-trip conversion
    #expect(roundTripHijriDate.year == hijriDate.year)
    #expect(roundTripHijriDate.month == hijriDate.month)
    #expect(roundTripHijriDate.day == hijriDate.day)

    // Test conversion with specific calendar
    let calendar = HijriCalendar.default
    let gregorianDateWithCalendar = hijriDate.toGregorianDate(using: calendar)
    let roundTripHijriDateWithCalendar = try HijriDate(from: gregorianDateWithCalendar, calendar: calendar)

    #expect(roundTripHijriDateWithCalendar.year == hijriDate.year)
    #expect(roundTripHijriDateWithCalendar.month == hijriDate.month)
    #expect(roundTripHijriDateWithCalendar.day == hijriDate.day)
}

@Test func testHijriDateComparison() {
    let date1 = HijriDate(year: 1445, month: 9, day: 1)
    let date2 = HijriDate(year: 1445, month: 9, day: 2)
    let date3 = HijriDate(year: 1445, month: 10, day: 1)
    let date4 = HijriDate(year: 1446, month: 9, day: 1)
    let date5 = HijriDate(year: 1445, month: 9, day: 1)

    // Test equality
    #expect(date1 == date5)
    #expect(date1 != date2)

    // Test less than
    #expect(date1 < date2)
    #expect(date2 < date3)
    #expect(date3 < date4)

    // Test greater than
    #expect(date4 > date3)
    #expect(date3 > date2)
    #expect(date2 > date1)

    // Test less than or equal
    #expect(date1 <= date5)
    #expect(date1 <= date2)

    // Test greater than or equal
    #expect(date5 >= date1)
    #expect(date2 >= date1)
}

@Test func testHijriDateStringRepresentation() {
    let date = HijriDate(year: 1445, month: 9, day: 1)
    #expect(date.description == "1445-09-01")
}

// MARK: - HijriCalendar Tests

@Test func testHijriCalendarDateConversion() throws {
    let calendar = HijriCalendar.default

    // Test a known date conversion
    let gregorianDate = createDate(day: 11, month: 3, year: 2024) // Around 1 Ramadan 1445
    let hijriComponents = calendar.hijriComponents(from: gregorianDate)

    #expect(hijriComponents.year == 1445)
    #expect(hijriComponents.month == 9)
    #expect(hijriComponents.day >= 1 && hijriComponents.day <= 3) // Allow for slight variations

    // Test conversion back to Gregorian
    let hijriDate = HijriDate(year: hijriComponents.year, month: hijriComponents.month, day: hijriComponents.day)
    let backToGregorian = calendar.date(from: hijriDate)

    let gregorianCalendar = Calendar(identifier: .gregorian)
    let day = gregorianCalendar.component(.day, from: backToGregorian)
    let month = gregorianCalendar.component(.month, from: backToGregorian)
    let year = gregorianCalendar.component(.year, from: backToGregorian)

    // Should be close to March 11, 2024 (might be off by a day due to time zone)
    #expect(year == 2024)
    #expect(month == 3)
    #expect(day >= 10 && day <= 12)
}

@Test func testHijriCalendarValidation() {
    let calendar = HijriCalendar.default

    // Test valid dates
    #expect(calendar.isValidHijriDate(year: 1445, month: 9, day: 1))
    #expect(calendar.isValidHijriDate(year: 1445, month: 12, day: 29))

    // Test invalid dates
    #expect(!calendar.isValidHijriDate(year: 1445, month: 0, day: 1)) // Month 0
    #expect(!calendar.isValidHijriDate(year: 1445, month: 13, day: 1)) // Month 13
    #expect(!calendar.isValidHijriDate(year: 1445, month: 9, day: 0)) // Day 0
    #expect(!calendar.isValidHijriDate(year: 1445, month: 9, day: 31)) // Day 31 (max is 30)

    // Test dates at the boundaries of the supported range
    #expect(calendar.isValidHijriDate(year: 1318, month: 1, day: 1)) // First supported date
    #expect(calendar.isValidHijriDate(year: 1500, month: 12, day: 29)) // Last supported date

    // Test dates outside the supported range
    #expect(!calendar.isValidHijriDate(year: 1317, month: 12, day: 29)) // Before 1318
    #expect(!calendar.isValidHijriDate(year: 1501, month: 1, day: 1)) // After 1500
}

@Test func testUmmAlQuraDataRange() throws {
    let calendar = HijriCalendar.default

    // Test first date in range (1 Muharram 1318 AH)
    let firstDate = HijriDate(year: 1318, month: 1, day: 1)
    let firstGregorianDate = calendar.date(from: firstDate)
    let firstHijriDate = try HijriDate(from: firstGregorianDate, calendar: calendar)

    // Allow for a small variation due to time zone or implementation details
    #expect(firstHijriDate.year == 1318)
    #expect(firstHijriDate.month == 1)
    #expect(firstHijriDate.day >= 1 && firstHijriDate.day <= 2)

    // Test last date in range (29/30 Dhul-Hijjah 1500 AH)
    let lastDate = HijriDate(year: 1500, month: 12, day: 29)
    let lastGregorianDate = calendar.date(from: lastDate)
    let lastHijriDate = try HijriDate(from: lastGregorianDate, calendar: calendar)

    // Allow for a small variation due to time zone or implementation details
    #expect(lastHijriDate.year == 1500)
    #expect(lastHijriDate.month == 12)
    #expect(lastHijriDate.day >= 28 && lastHijriDate.day <= 29)
}

// MARK: - HijriDateFormatter Tests

@Test func testHijriDateFormatterBasic() throws {
    let date = HijriDate(year: 1445, month: 9, day: 1)
    let formatter = HijriDateFormatter()

    // Test default formatting
    let defaultFormat = try formatter.string(from: date)
    #expect(!defaultFormat.isEmpty)

    // Test with specific format
    formatter.dateFormat = "d/M/y"
    let shortFormat = try formatter.string(from: date)
    #expect(shortFormat == "1/9/1445")

    formatter.dateFormat = "dd/MM/yyyy"
    let fullFormat = try formatter.string(from: date)
    #expect(fullFormat == "01/09/1445")

    formatter.dateFormat = "d MMM y"
    let mediumFormat = try formatter.string(from: date)
    #expect(mediumFormat.contains("1"))
    #expect(mediumFormat.contains("1445"))
    #expect(mediumFormat.contains("Ramadan") || mediumFormat.contains("Ram"))

    formatter.dateFormat = "MMMM"
    let monthName = try formatter.string(from: date)
    #expect(monthName == "Ramadan")
}

@Test func testHijriDateFormatterLanguages() throws {
    let date = HijriDate(year: 1445, month: 9, day: 1)
    let formatter = HijriDateFormatter()
    formatter.dateFormat = "MMMM"

    // Test English
    formatter.locale = Locale(identifier: "en")
    let englishMonth = try formatter.string(from: date)
    #expect(englishMonth == "Ramadan")

    // Test Arabic
    formatter.locale = Locale(identifier: "ar")
    let arabicMonth = try formatter.string(from: date)
    #expect(arabicMonth == "رمضان")
}

@Test func testHijriDateFormatterStyles() throws {
    let date = HijriDate(year: 1445, month: 9, day: 1)
    let formatter = HijriDateFormatter()

    // Test different date styles
    formatter.dateFormat = nil

    formatter.dateStyle = .short
    let shortStyle = try formatter.string(from: date)
    #expect(shortStyle.contains("1/9/1445"))

    formatter.dateStyle = .medium
    let mediumStyle = try formatter.string(from: date)
    #expect(mediumStyle.contains("1"))
    #expect(mediumStyle.contains("1445"))
    #expect(mediumStyle.contains("Ram") || mediumStyle.contains("Ramadan"))

    formatter.dateStyle = .long
    let longStyle = try formatter.string(from: date)
    #expect(longStyle.contains("1"))
    #expect(longStyle.contains("1445"))
    #expect(longStyle.contains("Ramadan"))

    formatter.dateStyle = .full
    let fullStyle = try formatter.string(from: date)
    #expect(fullStyle.contains("1"))
    #expect(fullStyle.contains("1445"))
    #expect(fullStyle.contains("Ramadan"))
    // Full style should include weekday
    #expect(fullStyle.contains("Monday") || fullStyle.contains("Tuesday") ||
           fullStyle.contains("Wednesday") || fullStyle.contains("Thursday") ||
           fullStyle.contains("Friday") || fullStyle.contains("Saturday") ||
           fullStyle.contains("Sunday"))
}

// MARK: - Helper Methods

func createDate(day: Int, month: Int, year: Int) -> Date {
    var components = DateComponents()
    components.day = day
    components.month = month
    components.year = year

    let calendar = Calendar(identifier: .gregorian)
    return calendar.date(from: components) ?? Date()
}
