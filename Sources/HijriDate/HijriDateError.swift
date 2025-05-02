import Foundation

/// Represents errors that can occur when working with Hijri dates.
public enum HijriDateError: Error, Equatable {
    /// Invalid date components were provided
    case invalidDateComponents(details: String)
    
    /// The date is outside the valid Umm al-Qura calendar range
    case dateOutOfRange(details: String)
    
    /// The adjustment is invalid (would create an invalid month length)
    case invalidAdjustment(details: String)
    
    /// The adjustment cannot be found
    case adjustmentNotFound(details: String)
    
    /// Error parsing or processing JSON data
    case jsonProcessingError(details: String)
    
    /// The operation is not supported
    case unsupportedOperation(details: String)
    
    /// A general error with the Hijri date
    case generalError(details: String)
}

// MARK: - LocalizedError

extension HijriDateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidDateComponents(let details):
            return "Invalid date components: \(details)"
        case .dateOutOfRange(let details):
            return "Date is out of valid range: \(details)"
        case .invalidAdjustment(let details):
            return "Invalid adjustment: \(details)"
        case .adjustmentNotFound(let details):
            return "Adjustment not found: \(details)"
        case .jsonProcessingError(let details):
            return "JSON processing error: \(details)"
        case .unsupportedOperation(let details):
            return "Unsupported operation: \(details)"
        case .generalError(let details):
            return "Hijri date error: \(details)"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension HijriDateError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .invalidDateComponents(let details):
            return "HijriDateError.invalidDateComponents: \(details)"
        case .dateOutOfRange(let details):
            return "HijriDateError.dateOutOfRange: \(details)"
        case .invalidAdjustment(let details):
            return "HijriDateError.invalidAdjustment: \(details)"
        case .adjustmentNotFound(let details):
            return "HijriDateError.adjustmentNotFound: \(details)"
        case .jsonProcessingError(let details):
            return "HijriDateError.jsonProcessingError: \(details)"
        case .unsupportedOperation(let details):
            return "HijriDateError.unsupportedOperation: \(details)"
        case .generalError(let details):
            return "HijriDateError.generalError: \(details)"
        }
    }
}
