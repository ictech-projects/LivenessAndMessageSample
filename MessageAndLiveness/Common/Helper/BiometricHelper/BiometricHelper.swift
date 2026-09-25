//
//  BiometricHelper.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 09/02/26.
//

import Foundation
import LocalAuthentication

final class BiometricHelper {
	func authenticate(reason: String) async throws -> Bool {
		let context = LAContext()
		var error: NSError?
		
		guard context.canEvaluatePolicy(
			.deviceOwnerAuthenticationWithBiometrics,
			error: &error
		) else {
			throw error ?? NSError(domain: "Biometric", code: -1)
		}
		
		return try await withCheckedThrowingContinuation { continuation in
			context.evaluatePolicy(
				.deviceOwnerAuthenticationWithBiometrics,
				localizedReason: reason
			) { success, authError in
				if let authError = authError {
					continuation.resume(throwing: authError)
				} else {
					continuation.resume(returning: success)
				}
			}
		}
	}
}
