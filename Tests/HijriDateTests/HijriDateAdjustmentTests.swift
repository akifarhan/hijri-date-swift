import Testing
import Foundation
@testable import HijriDate

struct HijriDateAdjustmentTests {

    // MARK: - Basic Testing with English Language

    @Test func basicHijriDateWithEnglish() async throws {
        // Test a known date conversion (using a date within the Umm al-Qura range)
        let calendar = HijriCalendar.default

        // Get the current date in Hijri
        let today = Date()
        let hijriToday = calendar.hijriDate(from: today)

        // Verify the date is valid
        #expect(calendar.isValidHijriDate(year: hijriToday.year, month: hijriToday.month, day: hijriToday.day))

        // Test formatting with English language
        let formatter = HijriDateFormatter()
        formatter.language = .english

        formatter.dateFormat = "d MMMM y"
        let formattedDate = try formatter.string(from: hijriToday)
        #expect(!formattedDate.isEmpty)

        print("Current Hijri date (English): \(formattedDate)")

        // Test with a more complex format
        formatter.dateFormat = "EEEE, d MMMM y (d-M-y)"
        let complexFormat = try formatter.string(from: hijriToday)
        #expect(!complexFormat.isEmpty)

        print("Formatted current date (English): \(complexFormat)")
    }

    // MARK: - Calendar Adjustments using addAdjustment

    @Test func calendarAdjustments() async throws {
        // Create a calendar adjustment object
        let calendarAdjustment = HijriCalendarAdjustment()

        // Following the PHP test case: Set 1 Ramadan 1446 to be March 2, 2025
        print("\n===== Calendar Adjustments using addAdjustment =====")

        // Set 1 Ramadan 1446 to be March 2, 2025
        let gregorianDate1 = createDate(day: 2, month: 3, year: 2025)
        print("Setting 1 Ramadan 1446 to March 2, 2025:")
        try calendarAdjustment.addAdjustment(month: 9, year: 1446, gregorianDate: gregorianDate1)
        print("Adjustment result: Success")

        // Set 1 Shawwal 1446 to be March 31, 2025
        let gregorianDate2 = createDate(day: 31, month: 3, year: 2025)
        print("Setting 1 Shawwal 1446 to March 31, 2025:")
        try calendarAdjustment.addAdjustment(month: 10, year: 1446, gregorianDate: gregorianDate2)
        print("Adjustment result: Success")

        // Get the adjustment data
        let adjustmentData = calendarAdjustment.getAdjustmentData()
        #expect(!adjustmentData.isEmpty)
        print("Adjustment data: \(adjustmentData)")

        // MARK: - Validation of Adjustments

        print("\n===== Validation of Adjustments =====")

        // Check if March 2, 2025 is now 1 Ramadan 1446
        let hijriDate1 = calendarAdjustment.hijriDate(from: gregorianDate1)
        let formatter = HijriDateFormatter(calendar: calendarAdjustment)
        formatter.language = .english
        formatter.dateFormat = "d MMM y"
        let formattedDate1 = try formatter.string(from: hijriDate1)

        print("March 2, 2025 in Hijri calendar: \(formattedDate1)")
        print("Is March 2, 2025 = 1 Ramadan 1446? \(hijriDate1.day == 1 && hijriDate1.month == 9 && hijriDate1.year == 1446 ? "YES" : "NO")")

        #expect(hijriDate1.day == 1)
        #expect(hijriDate1.month == 9)
        #expect(hijriDate1.year == 1446)

        // Check if March 31, 2025 is now 1 Shawwal 1446
        let hijriDate2 = calendarAdjustment.hijriDate(from: gregorianDate2)
        let formattedDate2 = try formatter.string(from: hijriDate2)

        print("March 31, 2025 in Hijri calendar: \(formattedDate2)")
        print("Is March 31, 2025 = 1 Shawwal 1446? \(hijriDate2.day == 1 && hijriDate2.month == 10 && hijriDate2.year == 1446 ? "YES" : "NO")")

        #expect(hijriDate2.day == 1)
        #expect(hijriDate2.month == 10)
        #expect(hijriDate2.year == 1446)

        // MARK: - Date Formatting Examples

        print("\n===== Date Formatting Examples =====")

        // Format dates with different formats
        formatter.dateFormat = "EEEE, d MMM y"
        let shortFormat1 = try formatter.string(from: hijriDate1)
        print("March 2, 2025 (1 Ramadan 1446) short format: \(shortFormat1)")

        formatter.dateFormat = "EEEE, d MMMM y"
        let longFormat1 = try formatter.string(from: hijriDate1)
        print("March 2, 2025 (1 Ramadan 1446) long format: \(longFormat1)")

        formatter.dateFormat = "EEEE, d MMM y"
        let shortFormat2 = try formatter.string(from: hijriDate2)
        print("March 31, 2025 (1 Shawwal 1446) short format: \(shortFormat2)")

        formatter.dateFormat = "EEEE, d MMMM y"
        let longFormat2 = try formatter.string(from: hijriDate2)
        print("March 31, 2025 (1 Shawwal 1446) long format: \(longFormat2)")
    }

    // MARK: - Serialization and Deserialization

    @Test func serializationDeserialization() async throws {
        // Create a calendar adjustment object
        let calendarAdjustment = HijriCalendarAdjustment()

        // Set 1 Ramadan 1446 to be March 2, 2025
        let gregorianDate1 = createDate(day: 2, month: 3, year: 2025)
        try calendarAdjustment.addAdjustment(month: 9, year: 1446, gregorianDate: gregorianDate1)

        // Set 1 Shawwal 1446 to be March 31, 2025
        let gregorianDate2 = createDate(day: 31, month: 3, year: 2025)
        try calendarAdjustment.addAdjustment(month: 10, year: 1446, gregorianDate: gregorianDate2)

        // Get the JSON string
        let json = try calendarAdjustment.getAdjustmentDataAsJSON()
        print("Adjustment data as JSON: \(json)")

        // Create a new calendar from the JSON string
        let newCalendarAdjustment = try HijriCalendarAdjustment.from(json: json)

        // Verify the new calendar has the same adjustments
        let adjustmentData = newCalendarAdjustment.getAdjustmentData()
        #expect(!adjustmentData.isEmpty)
        #expect(adjustmentData.count == 2)
    }

    // MARK: - Possible Starts

    @Test func possibleStarts() async throws {
        // Create a calendar adjustment object
        let calendarAdjustment = HijriCalendarAdjustment()

        // Get possible starts for Ramadan 1446
        let possibleStarts = calendarAdjustment.getPossibleStarts(month: 9, year: 1446)

        // There should be at least one possible start
        #expect(!possibleStarts.isEmpty)

        print("\n===== Possible Starts for Ramadan 1446 =====")
        for (index, start) in possibleStarts.enumerated() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: start.gregorianDate)
            print("\(index + 1). \(dateString) (Current start: \(start.isCurrentStart ? "Yes" : "No"), Auto-adjustments: \(start.autoAdjustments.count))")
        }
    }

    // MARK: - Auto-Adjustment Validation

    @Test func autoAdjustmentValidation() async throws {
        // Create a calendar adjustment object
        let calendarAdjustment = HijriCalendarAdjustment()

        print("\n===== Auto-Adjustment Validation =====")

        // Test Case 1: Move 1 Ramadan 1446 by 1 day (should succeed and auto-adjust)
        // First, get the default date for 1 Ramadan 1446
        let possibleStarts = calendarAdjustment.getPossibleStarts(month: 9, year: 1446)
        // Display all possible starts
        print("\n===== All Possible Starts for Ramadan 1446 =====")
        for (index, start) in possibleStarts.enumerated() {
            let formatter = DateFormatter()
            formatter.dateStyle = .full

            print("Option \(index + 1):")
            print("  Date: \(formatter.string(from: start.gregorianDate))")
            print("  Current Start: \(start.isCurrentStart ? "Yes" : "No")")
            print("  Julian Day: \(start.julianDay)")

            if !start.autoAdjustments.isEmpty {
                print("  Auto-Adjustments Required (\(start.autoAdjustments.count)):")
                for (adjIndex, adj) in start.autoAdjustments.enumerated() {
                    print("    \(adjIndex + 1). Month \(adj.month)/\(adj.year) to \(formatter.string(from: adj.gregorianDate))")
                }
            } else {
                print("  No Auto-Adjustments Required")
            }
            print("")
        }
        let defaultStart = possibleStarts.first(where: { $0.isCurrentStart })?.gregorianDate
        #expect(defaultStart != nil)


        guard let defaultStart = defaultStart else {
            throw Error("Failed to get default start date for Ramadan 1446")
        }

        // Move it one day forward
        let calendar = Calendar(identifier: .gregorian)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: defaultStart) else {
            throw Error("Failed to calculate next day")
        }

        let components = calendar.dateComponents([.year, .month, .day], from: nextDay)
        print("Moving 1 Ramadan 1446 from \(formatDate(defaultStart)) to \(formatDate(nextDay))")

        // Apply the adjustment
        try calendarAdjustment.addAdjustment(
            month: 9,
            year: 1446,
            gregorianYear: components.year!,
            gregorianMonth: components.month!,
            gregorianDay: components.day!
        )

        // Verify the adjustment was applied
        let adjustedDate = calendarAdjustment.hijriDate(from: nextDay)
        #expect(adjustedDate.day == 1)
        #expect(adjustedDate.month == 9)
        #expect(adjustedDate.year == 1446)

        print("Verification: \(formatDate(nextDay)) is now 1 Ramadan 1446")

        // Test Case 2: Check if Shaban (month 8) was auto-adjusted to maintain valid month length
        // Get the last day of Shaban
        let lastDayOfShabanHijri = HijriDate(year: 1446, month: 8, day: 30)
        let lastDayOfShaban = calendarAdjustment.date(from: lastDayOfShabanHijri)

        // Check if the date is valid (Shaban might have 29 or 30 days)
        let shabanLastDay = calendarAdjustment.hijriDate(from: lastDayOfShaban)
        print("Last day of Shaban 1446: \(shabanLastDay.day) Shaban 1446")
        #expect(shabanLastDay.day == 30 || shabanLastDay.day == 29, "Shaban should have 29 or 30 days")

        // Test Case 3: Check if Shawwal (month 10) was auto-adjusted
        let firstDayOfShawwalHijri = HijriDate(year: 1446, month: 10, day: 1)
        let firstDayOfShawwal = calendarAdjustment.date(from: firstDayOfShawwalHijri)

        let firstDayOfRamadanHijri = HijriDate(year: 1446, month: 9, day: 1)
        let firstDayOfRamadan = calendarAdjustment.date(from: firstDayOfRamadanHijri)

        // Calculate the length of Ramadan
        let ramadanLength = calendar.dateComponents([.day], from: firstDayOfRamadan, to: firstDayOfShawwal).day!

        print("Length of Ramadan 1446: \(ramadanLength) days")
        #expect(ramadanLength == 29 || ramadanLength == 30, "Ramadan should have 29 or 30 days")

        // Get the adjustment data to verify changes
        let adjustmentData = calendarAdjustment.getAdjustmentData()
        print("Final adjustment data: \(adjustmentData)")
        #expect(!adjustmentData.isEmpty)
    }

    // MARK: - Usage Example

    @Test func usageExample() async throws {
        print("\n===== Usage in Your Application =====")
        print("""
        To use these date adjustments in your application:

        // Create a calendar adjustment object
        let calendarAdjustment = HijriCalendarAdjustment()

        // Add your adjustments
        calendarAdjustment.addAdjustment(month: 9, year: 1446, gregorianDate: createDate(day: 2, month: 3, year: 2025))
        calendarAdjustment.addAdjustment(month: 10, year: 1446, gregorianDate: createDate(day: 31, month: 3, year: 2025))

        // Get the adjustment data as JSON for storage
        if let jsonData = calendarAdjustment.getAdjustmentDataAsJSON() {
            // Save jsonData to UserDefaults, a file, or a database
            UserDefaults.standard.set(jsonData, forKey: "HijriAdjustments")
        }

        // Later, load the adjustments
        if let savedJson = UserDefaults.standard.string(forKey: "HijriAdjustments") {
            let calendarAdjustment = HijriCalendarAdjustment()
            calendarAdjustment.setAdjustmentDataFromJSON(savedJson)

            // Use the calendar for date conversions
            let hijriDate = calendarAdjustment.hijriDate(from: Date())

            // Format the date
            let formatter = HijriDateFormatter(calendar: calendarAdjustment)
            formatter.dateFormat = "EEEE, d MMMM y"
            let formattedDate = formatter.string(from: hijriDate)
        }
        """)
    }

    // MARK: - Helper Methods

    private func createDate(day: Int, month: Int, year: Int) -> Date {
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year

        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components) ?? Date()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // Simple Error type for testing
    private struct Error: Swift.Error, CustomStringConvertible {
        let description: String

        init(_ description: String) {
            self.description = description
        }
    }
}
