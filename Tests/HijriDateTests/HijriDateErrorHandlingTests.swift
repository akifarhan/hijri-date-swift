import Testing
import Foundation
@testable import HijriDate

struct HijriDateErrorHandlingTests {
    
    // MARK: - HijriDate Error Handling Tests
    
    @Test func testHijriDateValidation() async throws {
        // Valid date should not throw
        let validDate = try HijriDate(validatedYear: 1445, month: 9, day: 15)
        #expect(validDate.year == 1445)
        #expect(validDate.month == 9)
        #expect(validDate.day == 15)
        
        // Invalid month should throw
        do {
            _ = try HijriDate(validatedYear: 1445, month: 13, day: 15)
            throw Error("Should have thrown an error for invalid month")
        } catch let error as HijriDateError {
            switch error {
            case .invalidDateComponents:
                // This is expected
                print("Correctly threw error for invalid month: \(error.localizedDescription)")
            default:
                throw Error("Unexpected error type: \(error)")
            }
        }
        
        // Invalid day should throw
        do {
            _ = try HijriDate(validatedYear: 1445, month: 9, day: 31)
            throw Error("Should have thrown an error for invalid day")
        } catch let error as HijriDateError {
            switch error {
            case .invalidDateComponents:
                // This is expected
                print("Correctly threw error for invalid day: \(error.localizedDescription)")
            default:
                throw Error("Unexpected error type: \(error)")
            }
        }
        
        // Year out of range should throw
        do {
            _ = try HijriDate(validatedYear: 1050, month: 9, day: 15)
            throw Error("Should have thrown an error for out of range year")
        } catch let error as HijriDateError {
            switch error {
            case .dateOutOfRange:
                // This is expected
                print("Correctly threw error for out of range year: \(error.localizedDescription)")
            default:
                throw Error("Unexpected error type: \(error)")
            }
        }
    }
    
    @Test func testHijriDateConversionWithValidation() async throws {
        // Valid date conversion
        let validDate = HijriDate(year: 1445, month: 9, day: 15)
        #expect(validDate.isValid)
        
        let gregorianDate = try validDate.toValidatedGregorianDate()
        #expect(gregorianDate != Date.distantPast)
        
        // Invalid date conversion
        let invalidDate = HijriDate(year: 1445, month: 9, day: 31) // No month has 31 days in Hijri calendar
        
        do {
            _ = try invalidDate.toValidatedGregorianDate()
            throw Error("Should have thrown an error for invalid date conversion")
        } catch let error as HijriDateError {
            switch error {
            case .invalidDateComponents:
                // This is expected
                print("Correctly threw error for invalid date conversion: \(error.localizedDescription)")
            default:
                throw Error("Unexpected error type: \(error)")
            }
        }
    }
    
    // MARK: - HijriCalendarAdjustment Error Handling Tests
    
    @Test func testCalendarAdjustmentValidation() async throws {
        let calendarAdjustment = HijriCalendarAdjustment()
        
        // Test valid adjustment using known valid dates
        do {
            // Get the possible starts for Ramadan 1446 (a safer option, as we know these are valid)
            let possibleStarts = calendarAdjustment.getPossibleStarts(month: 9, year: 1446)
            
            // Find a start date that doesn't require auto-adjustments (usually the default)
            guard let validStart = possibleStarts.first(where: { $0.isCurrentStart }) else {
                throw Error("Could not find a valid start date for testing")
            }
            
            // Create a Gregorian date
            let components = Calendar(identifier: .gregorian).dateComponents(
                [.year, .month, .day],
                from: validStart.gregorianDate
            )
            
            // This should succeed
            try calendarAdjustment.addAdjustment(
                month: 9,
                year: 1446,
                gregorianYear: components.year!,
                gregorianMonth: components.month!,
                gregorianDay: components.day!
            )
            print("Successfully applied valid adjustment")
        } catch {
            throw Error("Valid adjustment should not throw: \(error)")
        }
        
        // Test invalid month
        do {
            let today = Date()
            try calendarAdjustment.addAdjustment(month: 13, year: 1445, gregorianDate: today)
            throw Error("Should have thrown an error for invalid month")
        } catch let error as HijriDateError {
            switch error {
            case .invalidDateComponents:
                // This is expected
                print("Correctly threw error for invalid month: \(error.localizedDescription)")
            default:
                throw Error("Unexpected error type: \(error)")
            }
        }
        
        // Test invalid year (out of range)
        do {
            let today = Date()
            try calendarAdjustment.addAdjustment(month: 9, year: 1050, gregorianDate: today)
            throw Error("Should have thrown an error for out of range year")
        } catch let error as HijriDateError {
            switch error {
            case .dateOutOfRange:
                // This is expected
                print("Correctly threw error for out of range year: \(error.localizedDescription)")
            default:
                throw Error("Unexpected error type: \(error)")
            }
        }
    }
    
    @Test func testRemoveAdjustmentErrorHandling() async throws {
        let calendarAdjustment = HijriCalendarAdjustment()
        
        // Test removing non-existent adjustment
        do {
            try calendarAdjustment.removeAdjustment(month: 9, year: 1445)
            throw Error("Should have thrown an error for non-existent adjustment")
        } catch let error as HijriDateError {
            switch error {
            case .adjustmentNotFound:
                // This is expected
                print("Correctly threw error for non-existent adjustment: \(error.localizedDescription)")
            default:
                throw Error("Unexpected error type: \(error)")
            }
        }
        
        // Add and then remove an adjustment using specific known dates from the HijriDateAdjustmentTests
        // This uses dates that are known to be valid for Ramadan 1446
        do {
            // Create a Gregorian date for March 2, 2025 (which is known to work)
            let gregorianComponents = DateComponents(
                calendar: Calendar(identifier: .gregorian),
                year: 2025,
                month: 3,
                day: 2
            )
            
            guard let gregorianDate = gregorianComponents.date else {
                throw Error("Failed to create date")
            }
            
            // First apply the adjustment (setting 1 Ramadan 1446 to March 2, 2025)
            try calendarAdjustment.addAdjustment(month: 9, year: 1446, gregorianDate: gregorianDate)
            
            // Verify it was applied
            let adjustmentData = calendarAdjustment.getAdjustmentData()
            #expect(!adjustmentData.isEmpty, "Adjustment data should not be empty")
            
            // Now remove the adjustment (should succeed)
            try calendarAdjustment.removeAdjustment(month: 9, year: 1446)
            print("Successfully removed adjustment")
        } catch {
            throw Error("Valid adjustment operations should not throw: \(error.localizedDescription)")
        }
    }
    
    @Test func testJSONProcessingErrorHandling() async throws {
        let calendarAdjustment = HijriCalendarAdjustment()
        
        // Test valid JSON processing with known dates
        do {
            // Create a Gregorian date for March 2, 2025 (which is known to work)
            let gregorianComponents = DateComponents(
                calendar: Calendar(identifier: .gregorian),
                year: 2025,
                month: 3,
                day: 2
            )
            
            guard let gregorianDate = gregorianComponents.date else {
                throw Error("Failed to create date")
            }
            
            // First apply the adjustment (setting 1 Ramadan 1446 to March 2, 2025)
            try calendarAdjustment.addAdjustment(month: 9, year: 1446, gregorianDate: gregorianDate)
            
            // Verify adjustment was applied
            let initialData = calendarAdjustment.getAdjustmentData()
            #expect(!initialData.isEmpty, "Adjustment should be applied before testing JSON")
            
            // Get JSON representation
            let json = try calendarAdjustment.getAdjustmentDataAsJSON()
            print("Successfully generated JSON: \(json)")
            #expect(!json.isEmpty, "JSON should not be empty")
            
            // Create a new calendar from the JSON
            let newCalendar = try HijriCalendarAdjustment.from(json: json)
            
            // Verify the adjustment was preserved
            let adjustmentData = newCalendar.getAdjustmentData()
            #expect(!adjustmentData.isEmpty, "Adjustment data should not be empty after parsing JSON")
            
            // Test setting adjustments from JSON
            let thirdCalendar = HijriCalendarAdjustment()
            try thirdCalendar.setAdjustmentDataFromJSON(json)
            
            // Verify the adjustment was set
            let thirdCalendarData = thirdCalendar.getAdjustmentData()
            #expect(!thirdCalendarData.isEmpty, "Adjustment data should not be empty after setting from JSON")
        } catch {
            throw Error("Valid JSON operations should not throw: \(error.localizedDescription)")
        }
        
        // Test invalid JSON
        do {
            let invalidJson = "{invalid:json}"
            let _ = try HijriCalendarAdjustment.from(json: invalidJson) // Adding let _ to explicitly acknowledge unused result
            throw Error("Should have thrown an error for invalid JSON")
        } catch let error as HijriDateError {
            switch error {
            case .jsonProcessingError:
                // This is expected
                print("Correctly threw error for invalid JSON: \(error.localizedDescription)")
            default:
                throw Error("Unexpected error type: \(error)")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Simple Error type for testing
    private struct Error: Swift.Error, CustomStringConvertible {
        let description: String
        
        init(_ description: String) {
            self.description = description
        }
    }
}
