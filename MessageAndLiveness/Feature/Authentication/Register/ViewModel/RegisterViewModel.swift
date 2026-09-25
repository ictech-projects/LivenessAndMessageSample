//
//  RegisterViewModel.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import Combine
import Foundation

@MainActor
final class RegisterViewModel: ObservableObject {

	@Published var fullName = ""
	@Published var email = ""
	@Published var password = ""
	@Published var confirmPassword = ""
	@Published var isPasswordVisible = false
	@Published var isConfirmVisible = false

	@Published var fullNameError: String?
	@Published var emailError: String?
	@Published var passwordError: String?
	@Published var confirmError: String?

	@Published var isLoading = false
	@Published var alertMessage: String?

	/// Called once the account is created — the session then routes to the
	/// identity + liveness gate before Home.
	var onRegistered: ((AuthUser) -> Void)?

	private let authRepository: any AuthenticationRepository

	init(authRepository: some AuthenticationRepository = BirchLabsAuthenticationRepository()) {
		self.authRepository = authRepository
	}

	var isAlertPresented: Bool {
		get { alertMessage != nil }
		set { if !newValue { alertMessage = nil } }
	}

	func continueTapped() {
		guard validate() else { return }
		Task { await register() }
	}

	// MARK: - Private

	private func validate() -> Bool {
		fullNameError = InputValidator.isNonEmptyName(fullName) ? nil : "Please enter your full name."
		emailError = InputValidator.isValidEmail(email) ? nil : "Please enter a valid email address."
		passwordError = InputValidator.passwordIssue(password)
		confirmError = (confirmPassword == password) ? nil : "Passwords don't match."
		return fullNameError == nil && emailError == nil && passwordError == nil && confirmError == nil
	}

	private func register() async {
		isLoading = true
		defer { isLoading = false }

		do {
			let user = try await authRepository.register(
				fullName: fullName.trimmingCharacters(in: .whitespaces),
				email: email.trimmingCharacters(in: .whitespaces),
				password: password,
				passwordConfirmation: confirmPassword
			)
			onRegistered?(user)
		} catch {
			alertMessage = (error as? AuthError)?.errorDescription ?? error.localizedDescription
		}
	}
}
