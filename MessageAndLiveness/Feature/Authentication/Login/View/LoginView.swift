//
//  LoginView.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import SwiftUI

struct LoginView: View {

	@EnvironmentObject private var session: SessionStore
	@StateObject private var viewModel = LoginViewModel()

	var body: some View {
		AuthScaffold(
			title: "Welcome back",
			subtitle: "Sign in and verify it's really you"
		) {
			VStack(spacing: 24) {
				fields
				signInButton
				divider
				registerLink
			}
		}
		.overlay { if viewModel.isLoading { LoadingOverlay(message: "Signing you in…") } }
		.baseAlert(
			isPresented: $viewModel.isAlertPresented,
			type: .error,
			title: "Couldn't sign in",
			message: viewModel.alertMessage ?? "",
			confirmButtonColor: (text: .white, background: .brandSecondary, stroke: .clear),
			confirmLabel: Text("OK"),
			confirmAction: { viewModel.isAlertPresented = false }
		)
		.onAppear {
			viewModel.onAuthenticated = { user in
				session.handleAuthenticated(user)
			}
		}
	}

	private var fields: some View {
		VStack(spacing: 20) {
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
			.submitLabel(.next)

			PasswordField(
				title: "Password",
				placeholder: "Your password",
				text: $viewModel.password,
				isVisible: $viewModel.isPasswordVisible,
				error: viewModel.passwordError,
				submitLabel: .go,
				onSubmit: { viewModel.signInTapped() }
			)
		}
	}

	private var signInButton: some View {
		PrimaryButton(size: .large, action: viewModel.signInTapped) {
			Text("Sign In")
		}
	}

	private var divider: some View {
		HStack(spacing: 12) {
			Rectangle().fill(Color.neutral40).frame(height: 1)
			Text("or")
				.font(.baseStyle(size: 13, weight: .regular))
				.foregroundStyle(.neutral60)
			Rectangle().fill(Color.neutral40).frame(height: 1)
		}
	}

	private var registerLink: some View {
		HStack(spacing: 4) {
			Text("New here?")
				.font(.baseStyle(size: 14, weight: .regular))
				.foregroundStyle(.neutral70)

			NavigationLink {
				RegisterView()
			} label: {
				Text("Create an account")
					.font(.baseStyle(size: 14, weight: .bold))
					.foregroundStyle(.brandSecondary)
			}
		}
	}
}

#Preview {
	NavigationStack {
		LoginView()
			.environmentObject(SessionStore())
	}
}
