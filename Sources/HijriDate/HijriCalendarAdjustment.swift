import Foundation

/// A class that provides functionality to adjust the Hijri calendar.
///
/// HijriCalendarAdjustment extends HijriCalendar to provide functionality for adjusting
/// the Umm al-Qura calendar data. This allows for customization of the Hijri calendar
/// to match local observations or official announcements.
public class HijriCalendarAdjustment: HijriCalendar, @unchecked Sendable {

    // MARK: - Properties

    /// The original Umm al-Qura data without any adjustments.
    private var umDataClear: [Int]

    // MARK: - Initialization

    /// Creates a new HijriCalendarAdjustment with default settings.
    public override init() {
        self.umDataClear = HijriCalendar.loadUmmAlQuraData()
        super.init()
    }

    /// Creates a new HijriCalendarAdjustment with the specified settings.
    ///
    /// - Parameters:
    ///   - useUmmAlQura: Whether to use the Umm al-Qura algorithm.
    ///   - adjustmentData: The adjustment data for the Umm al-Qura calendar.
    public override init(useUmmAlQura: Bool, adjustmentData: [Int: Int] = [:]) {
        self.umDataClear = HijriCalendar.loadUmmAlQuraData()
        super.init(useUmmAlQura: useUmmAlQura, adjustmentData: adjustmentData)
    }

    // MARK: - Adjustment Methods

    /// Adds an adjustment to the Hijri calendar.
    ///
    /// - Parameters:
    ///   - month: The Hijri month to adjust.
    ///   - year: The Hijri year to adjust.
    ///   - gregorianDate: The Gregorian date that should correspond to the 1st of the Hijri month.
    /// - Throws: `HijriDateError` if the adjustment couldn't be applied.
    public func addAdjustment(month: Int, year: Int, gregorianDate: Date) throws {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: gregorianDate)

        guard let gYear = components.year, let gMonth = components.month, let gDay = components.day else {
            throw HijriDateError.invalidDateComponents(details: "Could not extract date components from the given Gregorian date")
        }

        try addAdjustment(month: month, year: year, gregorianYear: gYear, gregorianMonth: gMonth, gregorianDay: gDay)
    }

    /// Adds an adjustment to the Hijri calendar.
    ///
    /// - Parameters:
    ///   - month: The Hijri month to adjust.
    ///   - year: The Hijri year to adjust.
    ///   - gregorianYear: The Gregorian year.
    ///   - gregorianMonth: The Gregorian month.
    ///   - gregorianDay: The Gregorian day.
    /// - Throws: `HijriDateError` if the adjustment couldn't be applied.
    public func addAdjustment(month: Int, year: Int, gregorianYear: Int, gregorianMonth: Int, gregorianDay: Int) throws {
        // Validate inputs
        if month < 1 || month > 12 {
            throw HijriDateError.invalidDateComponents(details: "Month must be between 1 and 12")
        }
        
        if year < HijriCalendar.umStartYear || year > HijriCalendar.umEndYear {
            throw HijriDateError.dateOutOfRange(details: "Year \(year) is outside the valid range (\(HijriCalendar.umStartYear)-\(HijriCalendar.umEndYear))")
        }
        
        // Calculate the offset for the month and year
        let offset = monthToOffset(month: month, year: year)
        
        if offset <= 0 || offset >= umData.count {
            throw HijriDateError.dateOutOfRange(details: "Month \(month) of year \(year) is outside the valid range")
        }
        
        // Calculate the Modified Julian Day for the Gregorian date
        guard let mjd = gregorianToMJD(year: gregorianYear, month: gregorianMonth, day: gregorianDay) else {
            throw HijriDateError.invalidDateComponents(details: "Invalid Gregorian date components: year=\(gregorianYear), month=\(gregorianMonth), day=\(gregorianDay)")
        }
        
        // Validate the month length (days between this month and previous month)
        if !isValidAdjustment(offset: offset, newValue: mjd) {
            throw HijriDateError.invalidAdjustment(details: "Adjustment would create an invalid month length (must be 29 or 30 days)")
        }
        
        // Get any automatic adjustments needed to maintain valid month lengths
        let autoAdjustments = checkAutoAdjustments(offset: offset, value: mjd)
        
        // Apply the main adjustment
        if umDataClear[offset] == mjd {
            adjustmentData.removeValue(forKey: offset)
        } else {
            adjustmentData[offset] = mjd
        }
        
        // Apply all automatic adjustments
        for (key, value) in autoAdjustments {
            if umDataClear[key] == value {
                adjustmentData.removeValue(forKey: key)
            } else {
                adjustmentData[key] = value
            }
        }
        
        // Update the Umm al-Qura data with all adjustments
        for (key, value) in adjustmentData {
            umData[key] = value
        }
    }

    /// Removes an adjustment from the Hijri calendar.
    ///
    /// - Parameters:
    ///   - month: The Hijri month to remove the adjustment for.
    ///   - year: The Hijri year to remove the adjustment for.
    /// - Throws: `HijriDateError` if the adjustment couldn't be removed.
    public func removeAdjustment(month: Int, year: Int) throws {
        // Validate inputs
        if month < 1 || month > 12 {
            throw HijriDateError.invalidDateComponents(details: "Month must be between 1 and 12")
        }
        
        if year < HijriCalendar.umStartYear || year > HijriCalendar.umEndYear {
            throw HijriDateError.dateOutOfRange(details: "Year \(year) is outside the valid range (\(HijriCalendar.umStartYear)-\(HijriCalendar.umEndYear))")
        }

        // Get the offset for the Hijri month
        let offset = monthToOffset(month: month, year: year)

        // Check if the adjustment exists
        if !adjustmentData.keys.contains(offset) {
            throw HijriDateError.adjustmentNotFound(details: "No adjustment found for month \(month) of year \(year)")
        }

        // Create a copy of the current adjustment data
        var newAdjustmentData = adjustmentData

        // Remove the adjustment
        newAdjustmentData.removeValue(forKey: offset)

        // Check for auto-deletions
        let autoDeletions = checkAutoDeletions(offset: offset)

        // Apply auto-deletions
        for key in autoDeletions {
            newAdjustmentData.removeValue(forKey: key)
        }

        // Update the adjustment data
        adjustmentData = newAdjustmentData

        // Apply adjustments to the Umm al-Qura data
        var newUmData = umDataClear
        for (key, value) in adjustmentData {
            if key >= 0 && key < newUmData.count {
                newUmData[key] = value
            }
        }

        // Update the Umm al-Qura data
        umData = newUmData
    }

    /// Gets the adjustment data.
    ///
    /// - Returns: The adjustment data as a dictionary.
    public func getAdjustmentData() -> [Int: Int] {
        return adjustmentData
    }

    /// Gets the adjustment data as a JSON string.
    ///
    /// - Returns: The adjustment data as a JSON string.
    /// - Throws: `HijriDateError.jsonProcessingError` if JSON serialization failed.
    public func getAdjustmentDataAsJSON() throws -> String {
        // Convert Int keys to String keys for JSON serialization
        var stringKeyedData: [String: Int] = [:]
        for (key, value) in adjustmentData {
            stringKeyedData[String(key)] = value
        }

        let data = try JSONSerialization.data(withJSONObject: stringKeyedData, options: [])
        
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw HijriDateError.jsonProcessingError(details: "Failed to convert JSON data to string")
        }
        
        return jsonString
    }

    /// Creates a HijriCalendarAdjustment from a JSON string.
    ///
    /// - Parameter json: The JSON string containing the adjustment data.
    /// - Returns: A HijriCalendarAdjustment with the specified adjustments.
    /// - Throws: `HijriDateError` if parsing failed.
    public static func from(json: String) throws -> HijriCalendarAdjustment {
        guard let data = json.data(using: .utf8) else {
            throw HijriDateError.jsonProcessingError(details: "Failed to convert JSON string to data")
        }

        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Int] else {
                throw HijriDateError.jsonProcessingError(details: "JSON data is not in the expected format")
            }

            var adjustmentData: [Int: Int] = [:]

            for (key, value) in jsonObject {
                if let offset = Int(key) {
                    adjustmentData[offset] = value
                }
            }

            return HijriCalendarAdjustment(useUmmAlQura: true, adjustmentData: adjustmentData)
        } catch let error as HijriDateError {
            throw error
        } catch {
            throw HijriDateError.jsonProcessingError(details: "JSON deserialization failed: \(error.localizedDescription)")
        }
    }

    /// Sets the adjustment data from a JSON string.
    ///
    /// - Parameter json: The JSON string containing the adjustment data.
    /// - Throws: `HijriDateError` if the adjustment data couldn't be set.
    public func setAdjustmentDataFromJSON(_ json: String) throws {
        guard let data = json.data(using: .utf8) else {
            throw HijriDateError.jsonProcessingError(details: "Failed to convert JSON string to data")
        }

        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Int] else {
                throw HijriDateError.jsonProcessingError(details: "JSON data is not in the expected format")
            }

            // Create a new adjustment data dictionary
            var newAdjustmentData: [Int: Int] = [:]

            // Parse the JSON object
            for (key, value) in jsonObject {
                if let offset = Int(key) {
                    newAdjustmentData[offset] = value
                }
            }

            // Apply the adjustment data
            adjustmentData = newAdjustmentData

            // Apply adjustments to the Umm al-Qura data
            var newUmData = umDataClear
            for (key, value) in adjustmentData {
                if key >= 0 && key < newUmData.count {
                    newUmData[key] = value
                }
            }

            // Update the Umm al-Qura data
            umData = newUmData
        } catch let error as HijriDateError {
            throw error
        } catch {
            throw HijriDateError.jsonProcessingError(details: "JSON deserialization failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    /// Converts a Gregorian date to Modified Julian Day.
    ///
    /// - Parameters:
    ///   - year: The Gregorian year.
    ///   - month: The Gregorian month (1-12).
    ///   - day: The Gregorian day of the month.
    /// - Returns: The Modified Julian Day, or nil if the date is invalid.
    private func gregorianToMJD(year: Int, month: Int, day: Int) -> Int? {
        // Validate inputs
        if month < 1 || month > 12 || day < 1 || day > 31 {
            return nil
        }
        
        // Convert Gregorian date to Julian day
        let julianDay = gregorianToJulianDay(year: year, month: month, day: day)
        
        // Convert Julian day to Modified Julian Day
        return julianDay - HijriCalendar.mjdFactor
    }

    /// Checks for automatic adjustments that need to be made when adding an adjustment.
    ///
    /// - Parameters:
    ///   - offset: The offset of the month being adjusted.
    ///   - value: The new value for the month.
    /// - Returns: A dictionary of automatic adjustments that need to be made.
    private func checkAutoAdjustments(offset: Int, value: Int) -> [Int: Int] {
        var autoAdjustments: [Int: Int] = [:]
        
        // Create a temporary copy of the Umm al-Qura data
        var adjustedUmData = umDataClear
        
        // Apply existing adjustments (except for the one being modified)
        for (key, val) in adjustmentData {
            if key != offset {
                adjustedUmData[key] = val
            }
        }
        
        // Apply the new adjustment
        adjustedUmData[offset] = value
        
        // Check and adjust subsequent months to maintain valid month lengths
        for nextOffset in (offset + 1)..<adjustedUmData.count {
            let monthLength = adjustedUmData[nextOffset] - adjustedUmData[nextOffset - 1]
            
            if monthLength < 29 {
                // Month is too short, adjust it to be 29 days
                autoAdjustments[nextOffset] = adjustedUmData[nextOffset - 1] + 29
                adjustedUmData[nextOffset] = autoAdjustments[nextOffset]!
            } else if monthLength > 30 {
                // Month is too long, adjust it to be 30 days
                autoAdjustments[nextOffset] = adjustedUmData[nextOffset - 1] + 30
                adjustedUmData[nextOffset] = autoAdjustments[nextOffset]!
            } else {
                // Month length is valid, no need to check further
                break
            }
        }
        
        return autoAdjustments
    }

    /// Checks for automatic deletions that need to be made when removing an adjustment.
    ///
    /// - Parameter offset: The offset of the month being removed.
    /// - Returns: An array of offsets that need to be automatically deleted.
    private func checkAutoDeletions(offset: Int) -> [Int] {
        var autoDeletions: [Int] = []
        var tempAdjustmentData = adjustmentData

        // Remove the current adjustment
        tempAdjustmentData.removeValue(forKey: offset)

        // Create a temporary copy of the adjustment data
        var adjustedUmData = umDataClear
        for (key, value) in tempAdjustmentData {
            adjustedUmData[key] = value
        }

        // Check for months that need to be deleted
        for nextOffset in (offset + 1)..<adjustedUmData.count {
            if tempAdjustmentData.keys.contains(nextOffset) {
                let monthLength = adjustedUmData[nextOffset] - adjustedUmData[nextOffset - 1]

                if monthLength < 29 || monthLength > 30 {
                    // Month length is invalid, delete the adjustment
                    autoDeletions.append(nextOffset)
                    tempAdjustmentData.removeValue(forKey: nextOffset)

                    // Update the adjusted Umm al-Qura data
                    adjustedUmData = umDataClear
                    for (key, value) in tempAdjustmentData {
                        adjustedUmData[key] = value
                    }
                } else {
                    // Month length is valid, no need to delete further
                    break
                }
            } else {
                // No adjustment for this month, no need to check further
                break
            }
        }

        // Check for months that need to be deleted in the reverse direction
        for nextOffset in (0..<offset).reversed() {
            if tempAdjustmentData.keys.contains(nextOffset) {
                let monthLength = adjustedUmData[nextOffset + 1] - adjustedUmData[nextOffset]

                if monthLength < 29 || monthLength > 30 {
                    // Month length is invalid, delete the adjustment
                    autoDeletions.append(nextOffset)
                    tempAdjustmentData.removeValue(forKey: nextOffset)

                    // Update the adjusted Umm al-Qura data
                    adjustedUmData = umDataClear
                    for (key, value) in tempAdjustmentData {
                        adjustedUmData[key] = value
                    }
                } else {
                    // Month length is valid, no need to delete further
                    break
                }
            } else {
                // No adjustment for this month, no need to check further
                break
            }
        }

        return autoDeletions
    }

    /// Validates an adjustment to ensure it results in valid month lengths.
    ///
    /// - Parameters:
    ///   - offset: The offset of the month being adjusted.
    ///   - newValue: The new value for the month.
    /// - Returns: true if the adjustment is valid, false otherwise.
    private func isValidAdjustment(offset: Int, newValue: Int) -> Bool {
        // Check if the previous month exists
        if offset <= 0 {
            return false
        }
        
        // Calculate the length of the month (days between this month and previous month)
        let previousMonthStart = umData[offset - 1]
        let monthLength = newValue - previousMonthStart
        
        // In Islamic calendar, a month can only be 29 or 30 days
        return monthLength >= 29 && monthLength <= 30
    }

    /// Gets the possible start dates for a Hijri month.
    ///
    /// - Parameters:
    ///   - month: The Hijri month.
    ///   - year: The Hijri year.
    /// - Returns: An array of possible start dates for the Hijri month.
    public func getPossibleStarts(month: Int, year: Int) -> [PossibleStart] {
        var possibleStarts: [PossibleStart] = []

        // Get the offset for the Hijri month
        let offset = monthToOffset(month: month, year: year)

        // Check if the month is within the Umm al-Qura range
        if offset <= 0 || offset >= umData.count {
            return possibleStarts
        }

        // Get the start of the previous month
        let previousMonthStart = umData[offset - 1]

        // Calculate possible start dates (within a range of ±1 day from the current start)
        for mjd in (previousMonthStart + 29 - 1)...(previousMonthStart + 30 + 1) {
            // Check if this is the current start date
            let isCurrentStart = mjd == umData[offset]

            // Calculate the Gregorian date for this MJD
            let jd = mjd + HijriCalendar.mjdFactor
            let gregorianDate = julianDayToGregorian(julianDay: jd)

            // Check what other adjustments would be needed if this date is chosen
            var autoAdjustments: [AutoAdjustment] = []

            // Create a temporary copy of the adjustment data
            var tempAdjustmentData = adjustmentData

            // Add the new adjustment
            tempAdjustmentData[offset] = mjd

            // Check for auto-adjustments
            let autoAdjustmentDict = checkAutoAdjustments(offset: offset, value: mjd)

            // Convert auto-adjustments to the required format
            for (key, value) in autoAdjustmentDict {
                let (autoMonth, autoYear) = offsetToMonth(offset: key)
                let jd = value + HijriCalendar.mjdFactor
                let gregorianDate = julianDayToGregorian(julianDay: jd)

                autoAdjustments.append(AutoAdjustment(
                    month: autoMonth,
                    year: autoYear,
                    gregorianYear: gregorianDate.year,
                    gregorianMonth: gregorianDate.month,
                    gregorianDay: gregorianDate.day,
                    julianDay: jd
                ))
            }

            // Add this possible start to the list
            possibleStarts.append(PossibleStart(
                gregorianYear: gregorianDate.year,
                gregorianMonth: gregorianDate.month,
                gregorianDay: gregorianDate.day,
                julianDay: jd,
                isCurrentStart: isCurrentStart,
                autoAdjustments: autoAdjustments
            ))
        }

        return possibleStarts
    }

    // MARK: - Nested Types

    /// A struct representing a possible start date for a Hijri month.
    public struct PossibleStart {
        /// The Gregorian year of the possible start date.
        public let gregorianYear: Int

        /// The Gregorian month of the possible start date.
        public let gregorianMonth: Int

        /// The Gregorian day of the possible start date.
        public let gregorianDay: Int

        /// The Julian day of the possible start date.
        public let julianDay: Int

        /// Whether this is the current start date.
        public let isCurrentStart: Bool

        /// The auto-adjustments that would be needed if this date is chosen.
        public let autoAdjustments: [AutoAdjustment]

        /// The Gregorian date of the possible start date.
        public var gregorianDate: Date {
            var components = DateComponents()
            components.year = gregorianYear
            components.month = gregorianMonth
            components.day = gregorianDay

            let calendar = Calendar(identifier: .gregorian)
            return calendar.date(from: components) ?? Date()
        }
    }

    /// A struct representing an auto-adjustment that would be needed if a particular start date is chosen.
    public struct AutoAdjustment {
        /// The Hijri month that would be adjusted.
        public let month: Int

        /// The Hijri year that would be adjusted.
        public let year: Int

        /// The Gregorian year of the new start date.
        public let gregorianYear: Int

        /// The Gregorian month of the new start date.
        public let gregorianMonth: Int

        /// The Gregorian day of the new start date.
        public let gregorianDay: Int

        /// The Julian day of the new start date.
        public let julianDay: Int

        /// The Gregorian date of the new start date.
        public var gregorianDate: Date {
            var components = DateComponents()
            components.year = gregorianYear
            components.month = gregorianMonth
            components.day = gregorianDay

            let calendar = Calendar(identifier: .gregorian)
            return calendar.date(from: components) ?? Date()
        }
    }
}
