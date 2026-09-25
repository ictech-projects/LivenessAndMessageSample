//
//  Date+toString.swift
//  HJK
//
//  Created by Ewide Dev 5 on 17/09/25.
//

import Foundation

extension Date {
	/// Converts the date into a formatted string using the specified format.
	///
	/// - Parameter format: A `DateFormat` value that defines
	///   the desired date pattern (e.g. `dd/MM/yyyy`, `yyyy-MM-dd HH:mm`).
	///
	/// - Returns: A formatted `String` representation of the date.
	///
	/// - Example:
	/// ```swift
	/// let date = Date(timeIntervalSince1970: 0)
	/// let result = date.toString(format: .fullDateTime)
	/// // Possible output: "01/01/1970 00:00 AM"
	/// ```
	///
	/// - Input:
	///   - A valid `Date` instance.
	///   - A `DateFormat` enum case representing the format pattern.
	///
	/// - Output:
	///   - A string formatted according to the provided pattern
	///     using the `en_US_POSIX` locale.
	func toString(format: DateFormat) -> String {
		let formatter = DateFormatter()
		formatter.locale = Locale.current
		formatter.dateFormat = format.rawValue
		formatter.amSymbol = "AM"
		formatter.pmSymbol = "PM"
		formatter.locale = Locale(identifier: "en_US_POSIX")
		
		return formatter.string(from: self)
	}
}
