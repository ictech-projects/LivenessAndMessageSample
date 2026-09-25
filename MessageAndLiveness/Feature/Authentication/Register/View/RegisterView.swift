//
//  RegisterView.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import SwiftUI

struct RegisterView: View {

	@EnvironmentObject private var session: SessionStore
	@Environment(\.dismiss) private var dismiss
	@StateObject private var viewModel = RegisterViewModel()

	var body: some View {
		AuthScaffold(
			title: "Create account",
			subtitle: "A quick liveness check keeps your account secure",
			showsBack: true,
			onBack: { dismiss() }
		) {
			VStack(spacing: 24) {
				fields
				continueButton
				signInLink
			}
		}
		.navigationBarBackButtonHidden(true)
		.toolbar(.hidden, for: .navigationBar)
		.overlay { if viewModel.isLoading { LoadingOverlay(message: "Creating your account…") } }
		.baseAlert(
			isPresented: $viewModel.isAlertPresented,
			type: .error,
			title: "Couldn't create account",
			message: viewModel.alertMessage ?? "",
			confirmButtonColor: (text: .white, background: .brandSecondary, stroke: .clear),
			confirmLabel: Text("OK"),
			confirmAction: { viewModel.isAlertPresented = false }
		)
		.onAppear {
			viewModel.onRegistered = { user in
				session.handleAuthenticated(user)
			}
		}
	}

	private var fields: some View {
		VStack(spacing: 20) {
			TextField(text: $viewModel.fullName) {
				Text("Jane Appleseed")
					.font(.baseStyle(size: 16, weight: .regular))
					.foregroundStyle(.neutral60)
			}
			.withTitle(
				Text("Full name"),
				capitalization: .words,
				leftIcon: Image(.user),
				errorDescription: viewModel.fullNameError.map(Text.init)
			)

			TextField(text: $viewModel.email) {
				Text("you@example.com")
					.font(.baseStyle(size: 16, weight: .regular))
					.foregroundStyle(.neutral60)
			}
			.withTitle(
				Text("Email"),
				keyboardType: .emailAddress,
				leftIcon: Image(.user),
				errorDescription: viewModel.emailError.map(Text.init)
			)

			PasswordField(
				title: "Password",
				placeholder: "At least 8 characters",
				text: $viewModel.password,
				isVisible: $viewModel.isPasswordVisible,
				error: viewModel.passwordError,
				submitLabel: .next
			)

			PasswordField(
				title: "Confirm password",
				placeholder: "Re-enter your password",
				text: $viewModel.confirmPassword,
				isVisible: $viewModel.isConfirmVisible,
				error: viewModel.confirmError,
				submitLabel: .go,
				onSubmit: { viewModel.continueTapped() }
			)
		}
	}

	private var continueButton: some View {
		PrimaryButton(size: .large, action: viewModel.continueTapped) {
			Text("Create account")
		}
	}

	private var signInLink: some View {
		HStack(spacing: 4) {
			Text("Already have an account?")
				.font(.baseStyle(size: 14, weight: .regular))
				.foregroundStyle(.neutral70)

			Button {
				dismiss()
			} label: {
				Text("Sign in")
					.font(.baseStyle(size: 14, weight: .bold))
					.foregroundStyle(.brandSecondary)
			}
		}
	}
}

#Preview {
	NavigationStack {
		RegisterView()
			.environmentObject(SessionStore())
	}
}
