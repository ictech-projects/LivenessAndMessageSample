//
//  LoginViewModel.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {

	@Published var email = ""
	@Published var password = ""
	@Published var isPasswordVisible = false

	@Published var emailError: String?
	@Published var passwordError: String?

	@Published var isLoading = false
	@Published var alertMessage: String?

	/// Called after a correct login — the session then routes to the identity
	/// + liveness gate before Home.
	var onAuthenticated: ((AuthUser) -> Void)?

	private let authRepository: any AuthenticationRepository

	init(authRepository: some AuthenticationRepository = BirchLabsAuthenticationRepository()) {
		self.authRepository = authRepository
	}

	var isAlertPresented: Bool {
		get { alertMessage != nil }
		set { if !newValue { alertMessage = nil } }
	}

	func signInTapped() {
		guard validate() else { return }
		Task { await signIn() }
	}

	// MARK: - Private

	private func validate() -> Bool {
		emailError = InputValidator.isValidEmail(email) ? nil : "Please enter a valid email address."
		passwordError = password.isEmpty ? "Please enter your password." : nil
		return emailError == nil && passwordError == nil
	}

	private func signIn() async {
		isLoading = true
		defer { isLoading = false }

		do {
			let user = try await authRepository.signIn(
				email: email.trimmingCharacters(in: .whitespaces),
				password: password
			)
			onAuthenticated?(user)
		} catch {
			alertMessage = (error as? AuthError)?.errorDescription ?? error.localizedDescription
		}
	}
}
