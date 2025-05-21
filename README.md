# HijriDateSwift

A Swift package for working with the Islamic (Hijri) calendar system. This package provides comprehensive functionality for converting between Gregorian and Hijri dates, validating Hijri dates, and formatting Hijri dates for display.

*Inspired by [mrkindy/hijridate](https://github.com/mrkindy/hijridate/tree/main)*

## Features

- Convert between Gregorian and Hijri dates
- Support for both Umm al-Qura algorithm (official Saudi Arabia calendar) and tabular Islamic calendar
- Validate Hijri dates
- Customize Hijri dates through manual adjustments (e.g., based on moon sightings or official announcements)
- Format Hijri dates with localization support
- Calculate days in month, day of week, and other calendar arithmetic

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/akifarhan/hijri-date-swift.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. File > Swift Packages > Add Package Dependency
2. Enter the repository URL: `https://github.com/akifarhan/hijri-date-swift.git`

## Usage

### Basic Usage

```swift
import HijriDate

// Create a Hijri date
let hijriDate = HijriDate(year: 1445, month: 11, day: 15)

// Convert to Gregorian date
let gregorianDate = hijriDate.toGregorianDate()

// Create a Hijri date from a Gregorian date
do {
    let today = Date()
    let hijriToday = try HijriDate(from: today)
    print("Today in Hijri: \(hijriToday)")
} catch {
    print("Error converting date: \(error)")
}
```

### Validating Dates

```swift
// Create a Hijri date with validation
do {
    let validatedDate = try HijriDate(validatedYear: 1445, month: 11, day: 15)
    print("Valid date: \(validatedDate)")
} catch {
    print("Invalid date: \(error)")
}

// Check if a date is valid
let date = HijriDate(year: 1445, month: 13, day: 1)
if date.isValid {
    print("Date is valid")
} else {
    print("Date is invalid")
}
```

### Using Different Calendar Algorithms

```swift
// Create a calendar using the tabular Islamic algorithm
let tabularCalendar = HijriCalendar(useUmmAlQura: false)

// Convert a date using the tabular calendar
let hijriDate = HijriDate(year: 1445, month: 11, day: 15)
let gregorianDate = hijriDate.toGregorianDate(using: tabularCalendar)

// Create a Hijri date from a Gregorian date using the tabular calendar
do {
    let today = Date()
    let hijriToday = try HijriDate(from: today, calendar: tabularCalendar)
    print("Today in Hijri (tabular): \(hijriToday)")
} catch {
    print("Error converting date: \(error)")
}
```

### Formatting Dates

```swift
// Create a formatter
let formatter = HijriDateFormatter()

// Set the date style
formatter.dateStyle = .full

// Format a date
do {
    let hijriDate = HijriDate(year: 1445, month: 11, day: 15)
    let formattedDate = try formatter.string(from: hijriDate)
    print(formattedDate) // e.g., "Friday, 15 Dhul-Qadah 1445"
} catch {
    print("Error formatting date: \(error)")
}

// Use a custom format
formatter.dateFormat = "d MMMM y"
do {
    let hijriDate = HijriDate(year: 1445, month: 11, day: 15)
    let formattedDate = try formatter.string(from: hijriDate)
    print(formattedDate) // e.g., "15 Dhul-Qadah 1445"
} catch {
    print("Error formatting date: \(error)")
}

// Use a different locale
formatter.locale = Locale(identifier: "ar")
do {
    let hijriDate = HijriDate(year: 1445, month: 11, day: 15)
    let formattedDate = try formatter.string(from: hijriDate)
    print(formattedDate) // e.g., "١٥ ذو القعدة ١٤٤٥"
} catch {
    print("Error formatting date: \(error)")
}
```

### Adjusting the Calendar

The Hijri calendar can be adjusted to match local observations or official announcements. This is particularly important for religious purposes, where the start of months like Ramadan may be determined by moon sightings rather than astronomical calculations.

#### Basic Adjustments

```swift
// Create an adjustable calendar
let adjustableCalendar = HijriCalendarAdjustment()

// Method 1: Adjust using a Gregorian Date object
// Set 1 Ramadan 1446 to be March 2, 2025
let gregorianDate = DateComponents(calendar: Calendar(identifier: .gregorian),
                                  year: 2025, month: 3, day: 2).date!
do {
    try adjustableCalendar.addAdjustment(month: 9, year: 1446, gregorianDate: gregorianDate)
    print("Successfully adjusted 1 Ramadan 1446 to March 2, 2025")
} catch {
    print("Error adjusting calendar: \(error)")
}

// Method 2: Adjust using explicit Gregorian components
// Set 1 Shawwal 1446 to be March 31, 2025
do {
    try adjustableCalendar.addAdjustment(
        month: 10,              // Shawwal is month 10
        year: 1446,             // Hijri year
        gregorianYear: 2025,    // Gregorian year
        gregorianMonth: 3,      // March
        gregorianDay: 31        // 31st
    )
    print("Successfully adjusted 1 Shawwal 1446 to March 31, 2025")
} catch {
    print("Error adjusting calendar: \(error)")
}

// Use the adjusted calendar for date conversions
let ramadanFirst = HijriDate(year: 1446, month: 9, day: 1)
let gregorianRamadanFirst = ramadanFirst.toGregorianDate(using: adjustableCalendar)
print("Ramadan 1, 1446 corresponds to: \(gregorianRamadanFirst)") // Should be March 2, 2025
```

#### Auto-Adjustments

When you adjust a month's start date, the library automatically makes necessary adjustments to ensure month lengths remain valid (29 or 30 days). This maintains the integrity of the calendar system:

```swift
// When you adjust 1 Ramadan, the library may automatically adjust adjacent months
// to maintain valid month lengths (29 or 30 days)
let adjustableCalendar = HijriCalendarAdjustment()

// Get the current default start date for Ramadan 1446
let possibleStarts = adjustableCalendar.getPossibleStarts(month: 9, year: 1446)
if let defaultStart = possibleStarts.first(where: { $0.isCurrentStart }) {
    print("Default start of Ramadan 1446: \(defaultStart.gregorianDate)")

    // Check if this start date would require auto-adjustments
    if !defaultStart.autoAdjustments.isEmpty {
        print("This start date requires \(defaultStart.autoAdjustments.count) auto-adjustments")
    }
}

// After making an adjustment, verify the month length is still valid
do {
    let gregorianDate = DateComponents(calendar: Calendar(identifier: .gregorian),
                                      year: 2025, month: 3, day: 2).date!
    try adjustableCalendar.addAdjustment(month: 9, year: 1446, gregorianDate: gregorianDate)

    // Check the length of Ramadan
    let firstDayOfRamadan = HijriDate(year: 1446, month: 9, day: 1).toGregorianDate(using: adjustableCalendar)
    let lastDayOfRamadan = HijriDate(year: 1446, month: 9, day: 29).toGregorianDate(using: adjustableCalendar)

    let calendar = Calendar(identifier: .gregorian)
    let ramadanLength = calendar.dateComponents([.day], from: firstDayOfRamadan, to: lastDayOfRamadan).day! + 1

    print("Length of Ramadan 1446: \(ramadanLength) days") // Should be 29 or 30 days
} catch {
    print("Error adjusting calendar: \(error)")
}
```

#### Persistence with JSON

You can save and restore calendar adjustments using JSON serialization:

```swift
// Export adjustments to JSON for persistence
do {
    // After making adjustments
    let jsonString = try adjustableCalendar.getAdjustmentDataAsJSON()
    print("Adjustment data: \(jsonString)")

    // Save this JSON string to UserDefaults, a file, or a database
    UserDefaults.standard.set(jsonString, forKey: "HijriAdjustments")

    // Later, restore adjustments from JSON
    if let savedJSON = UserDefaults.standard.string(forKey: "HijriAdjustments") {
        let restoredCalendar = try HijriCalendarAdjustment.from(json: savedJSON)
        print("Successfully restored calendar adjustments")

        // Use the restored calendar
        let ramadanFirst = HijriDate(year: 1446, month: 9, day: 1)
        let gregorianDate = ramadanFirst.toGregorianDate(using: restoredCalendar)
        print("Ramadan 1, 1446 corresponds to: \(gregorianDate)") // Should match our adjustment
    }
} catch {
    print("Error processing adjustment data: \(error)")
}

// Alternative: Set adjustment data from JSON directly
do {
    let jsonString = "{\"1543\":20181,\"1544\":20211}" // Example adjustment data
    try adjustableCalendar.setAdjustmentDataFromJSON(jsonString)
    print("Successfully set adjustment data from JSON")
} catch {
    print("Error setting adjustment data: \(error)")
}
```

#### Exploring Possible Start Dates

You can explore all possible start dates for a Hijri month:

```swift
let adjustableCalendar = HijriCalendarAdjustment()

// Get possible starts for Ramadan 1446
let possibleStarts = adjustableCalendar.getPossibleStarts(month: 9, year: 1446)

print("Possible start dates for Ramadan 1446:")
for (index, start) in possibleStarts.enumerated() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    let dateString = dateFormatter.string(from: start.gregorianDate)

    print("\(index + 1). \(dateString)")
    print("   Current start: \(start.isCurrentStart ? "Yes" : "No")")
    print("   Auto-adjustments required: \(start.autoAdjustments.count)")
    print("   Julian day: \(start.julianDay)")
}

// Find the optimal start date (one that requires no auto-adjustments)
if let optimalStart = possibleStarts.first(where: { $0.autoAdjustments.isEmpty }) {
    print("Optimal start date: \(optimalStart.gregorianDate)")
}
```

#### Removing Adjustments

You can also remove previously applied adjustments:

```swift
do {
    try adjustableCalendar.removeAdjustment(month: 9, year: 1446)
    print("Successfully removed adjustment for Ramadan 1446")
} catch {
    print("Error removing adjustment: \(error)")
}
```

## Advanced Usage

### Getting Possible Start Dates for a Month

When adjusting the calendar, you might want to see the possible start dates for a month:

```swift
let adjustableCalendar = HijriCalendarAdjustment()
let possibleStarts = adjustableCalendar.getPossibleStarts(month: 9, year: 1445)

for start in possibleStarts {
    print("Possible start: \(start.gregorianDate), valid: \(start.isValid)")
}
```

### Custom Localization

You can create custom localization providers for different languages:

```swift
class MyCustomLocalizationProvider: HijriLocalizationProvider {
    func shortMonthName(for month: Int) -> String {
        // Return custom short month names
    }

    func fullMonthName(for month: Int) -> String {
        // Return custom full month names
    }

    func shortWeekdayName(for weekday: Int) -> String {
        // Return custom short weekday names
    }

    func fullWeekdayName(for weekday: Int) -> String {
        // Return custom full weekday names
    }

    var localeIdentifier: String {
        return "en-US-custom"
    }
}

// Register your custom provider
HijriDateFormatter.registerLocalizationProvider(MyCustomLocalizationProvider())
```

## Error Handling

The package uses the `HijriDateError` enum for error handling:

```swift
do {
    let invalidDate = try HijriDate(validatedYear: 1445, month: 13, day: 1)
} catch let error as HijriDateError {
    switch error {
    case .invalidDateComponents(let details):
        print("Invalid date components: \(details)")
    case .dateOutOfRange(let details):
        print("Date out of range: \(details)")
    default:
        print("Other error: \(error.localizedDescription)")
    }
}
```

## Limitations

- The Umm al-Qura calendar data is available for years 1318-1500 AH (approximately 1900-2077 CE)
- Adjustments can only be made within this range
- The tabular Islamic calendar can be used for dates outside this range, but may not match official calendars

## License

This package is available under the MIT license. See the LICENSE file for more info.
