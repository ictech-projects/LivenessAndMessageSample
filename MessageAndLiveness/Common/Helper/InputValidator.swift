//
//  InputValidator.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import Foundation

/// Small, reusable field validators for the auth forms.
enum InputValidator {

	static func isValidEmail(_ email: String) -> Bool {
		let trimmed = email.trimmingCharacters(in: .whitespaces)
		guard !trimmed.isEmpty else { return false }
		let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
		return trimmed.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
	}

	/// Returns a human-readable issue with the password, or `nil` if it's valid.
	static func passwordIssue(_ password: String) -> String? {
		if password.count < 8 {
			return "Password must be at least 8 characters."
		}
		let hasLetter = password.contains { $0.isLetter }
		let hasDigit = password.contains { $0.isNumber }
		if !hasLetter || !hasDigit {
			return "Use a mix of letters and numbers."
		}
		return nil
	}

	static func isNonEmptyName(_ name: String) -> Bool {
		name.trimmingCharacters(in: .whitespaces).count >= 2
	}
}
