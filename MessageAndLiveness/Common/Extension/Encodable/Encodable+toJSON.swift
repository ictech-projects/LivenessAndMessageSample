import Foundation

extension Encodable {
	/// Converts the conforming object into a JSON dictionary.
	///
	/// - Returns: A `[String: Any]` dictionary representation of the encoded object.
	///   Returns an empty dictionary (`[:]`) if encoding or serialization fails.
	///
	/// - Example:
	/// ```swift
	/// struct User: Encodable {
	///     let id: Int
	///     let name: String
	/// }
	///
	/// let user = User(id: 1, name: "John")
	/// let json = user.toJSON()
	/// // Output: ["id": 1, "name": "John"]
	/// ```
	///
	/// - Input:
	///   - Any type conforming to `Encodable`.
	///
	/// - Output:
	///   - A dictionary containing key-value pairs that match
	///     the encoded JSON structure.
	func toJSON() -> [String: Any] {
		guard let data =  try? JSONEncoder().encode(self),
					let dictionary = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed),
					let json = dictionary as? [String: Any] else {
			return [:]
		}
		
		return json
	}
	
	/// Converts the conforming object into raw JSON `Data`.
	///
	/// - Returns: A `Data` object containing the JSON-encoded representation.
	///   Returns empty `Data()` if encoding fails.
	///
	/// - Example:
	/// ```swift
	/// let user = User(id: 1, name: "John")
	/// let data = user.toJSONData()
	/// // Output: JSON data equivalent to:
	/// // { "id": 1, "name": "John" }
	/// ```
	///
	/// - Input:
	///   - Any type conforming to `Encodable`.
	///
	/// - Output:
	///   - A JSON-encoded `Data` instance suitable for
	///     network requests or persistence.
	func toJSONData() -> Data {
		guard let data =  try? JSONEncoder().encode(self) else {
			return Data()
		}
		
		return data
	}
}
