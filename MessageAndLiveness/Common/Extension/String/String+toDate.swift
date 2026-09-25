//
//  String+toDate.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 05/11/25.
//

import Foundation

extension String {
	/// Converts the string into a `Date` using the specified format.
	///
	/// - Parameter format: A `DateFormat` value that defines
	///   the expected date pattern of the string.
	///
	/// - Returns: A `Date` parsed from the string.
	///   Returns `Date()` (current date) if parsing fails.
	///
	/// - Example:
	/// ```swift
	/// let dateString = "05/11/2025"
	/// let date = dateString.toDate(format: .ddMMyyyy)
	/// // Input: "05/11/2025"
	/// // Output: Date representing 5 November 2025
	/// ```
	///
	/// - Input:
	///   - A string that matches the provided `DateFormat` pattern.
	///
	/// - Output:
	///   - A valid `Date` object if parsing succeeds.
	///   - The current date (`Date()`) if parsing fails.
	func toDate(format: DateFormat) -> Date {
		let formatter = DateFormatter()
		formatter.locale = Locale.current
		formatter.dateFormat = format.rawValue
		
		return formatter.date(from: self) ?? Date()
	}
}
