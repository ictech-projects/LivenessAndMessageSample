//
//  PasswordField.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import SwiftUI

/// A titled password field with a show/hide toggle.
///
/// SwiftUI's `SecureField` can't reveal its text, so this swaps between a
/// `SecureField` and a `TextField` while reusing the project's `.withTitle`
/// styling. `submitLabel`/`onSubmit` are applied on the container so they
/// propagate to whichever field is currently shown.
struct PasswordField: View {

	let title: String
	let placeholder: String
	@Binding var text: String
	@Binding var isVisible: Bool
	var error: String?
	var submitLabel: SubmitLabel = .go
	var onSubmit: () -> Void = {}

	var body: some View {
		Group {
			if isVisible {
				TextField(text: $text) { placeholderLabel }
					.withTitle(
						Text(title),
						leftIcon: Image(.lock),
						rightIcon: Image(.eye),
						errorDescription: error.map(Text.init),
						onRightIconPressed: { isVisible.toggle() }
					)
			} else {
				SecureField(text: $text) { placeholderLabel }
					.withTitle(
						Text(title),
						leftIcon: Image(.lock),
						rightIcon: Image(.eyeOff),
						errorDescription: error.map(Text.init),
						onRightIconPressed: { isVisible.toggle() }
					)
			}
		}
		.submitLabel(submitLabel)
		.onSubmit(onSubmit)
	}

	private var placeholderLabel: some View {
		Text(placeholder)
			.font(.baseStyle(size: 16, weight: .regular))
			.foregroundStyle(.neutral60)
	}
}
