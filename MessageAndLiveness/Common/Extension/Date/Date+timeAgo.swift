//
//  Date+timeAgo.swift
//  HJK
//
//  Created by Ewide Dev 5 on 19/09/25.
//

import Foundation

extension Date {
	/// Returns a localized, human-readable relative time string.
	///
	/// The result represents the time difference between the current date (`Date()`)
	/// and the receiver.
	///
	/// - Returns: A string describing how much time has passed.
	///
	/// - Example:
	/// ```swift
	/// let fiveMinutesAgo = Date().addingTimeInterval(-300)
	/// let result = fiveMinutesAgo.timeAgo()
	/// // Possible output: "5 minutes ago"
	/// ```
	///
	/// - Input:
	///   - A `Date` instance in the past.
	///
	/// - Output:
	///   - A formatted string such as:
	///     - "10 seconds ago"
	///     - "3 hours ago"
	///     - "2 days ago"
	///   - Returns `"Just now"` if formatting fails.
	func timeAgo() -> String {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .full
		formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute, .second]
		formatter.maximumUnitCount = 1
		
		let now = Date()
		let timeInterval = now.timeIntervalSince(self)
		
		guard let formattedString = formatter.string(from: timeInterval) else {
			return "Just now"
		}
		
		return "\(formattedString) ago"
	}
}
