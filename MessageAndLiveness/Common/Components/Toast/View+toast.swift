//
//  View+toast.swift
// MessageAndLiveness
//
//  Created by Arifin Firdaus on 28/01/26.
//

import SwiftUI

// MARK: - View Extension

extension View {
	/// Presents a lightweight, non-blocking toast message inspired by
	/// Android Toast (`android.widget.Toast`).
	///
	/// Unlike alerts or dialogs, a toast:
	/// - does not block user interaction
	/// - appears temporarily at the bottom of the screen
	/// - dismisses automatically after a short duration
	///
	/// Reference:
	/// https://developer.android.com/guide/topics/ui/notifiers/toasts
	///
	/// Usage:
	/// ```swift
	/// @State private var toast: ToastData?
	///
	/// toast = ToastData(message: "Saved successfully")
	/// ```
	func toast(_ toast: Binding<ToastData?>) -> some View {
		modifier(ToastModifier(toast: toast))
	}
}

// MARK: - Toast Data Model

/// Represents a transient toast message.
///
/// This model closely mirrors the behavior of Android Toast:
/// - simple text message
/// - fixed display duration
struct ToastData: Equatable {
	let text: Text
	let duration: TimeInterval
	
	/// Creates a toast with a message and optional duration.
	///
	/// - Parameters:
	///   - text: Text displayed in the toast.
	///   - duration: How long the toast stays visible (default: 2 seconds).
	init(
		text: Text,
		duration: TimeInterval = 2
	) {
		self.text = text
		self.duration = duration
	}
}

// MARK: - Toast View

/// Visual representation of a toast message.
///
/// Styled to resemble Android Toast:
/// - rounded capsule background
/// - high contrast text
/// - subtle shadow
struct ToastView: View {
	let text: Text
	
	var body: some View {
		text
			.font(.baseStyle(size: 14, weight: .medium))
			.foregroundStyle(.white)
			.padding(.horizontal, 16)
			.padding(.vertical, 10)
			.background(
				Capsule()
					.fill(Color.black.opacity(0.8))
			)
			.shadow(
				color: .black.opacity(0.25),
				radius: 4,
				x: 0,
				y: 2
			)
	}
}

// MARK: - Toast Modifier

/// Handles toast presentation and automatic dismissal.
///
/// The toast is:
/// - overlaid above the current content
/// - positioned at the bottom of the screen
/// - automatically dismissed after the specified duration
struct ToastModifier: ViewModifier {
	@Binding var toast: ToastData?
	@State private var isVisible = false
	
	func body(content: Content) -> some View {
		ZStack {
			content
			
			if let toast {
				VStack {
					Spacer()
					
					ToastView(text: toast.text)
						.padding(.bottom, 40)
						.opacity(isVisible ? 1 : 0)
						.transition(.move(edge: .bottom))
				}
				.task {
					withAnimation(.easeOut(duration: 0.25)) {
						isVisible = true
					}

					try? await Task.sleep(for: .seconds(toast.duration))

					withAnimation(.easeIn(duration: 0.25)) {
						isVisible = false
					}

					try? await Task.sleep(for: .seconds(0.25))
					self.toast = nil
				}
			}
		}
	}
}

// MARK: - Preview

struct ToastPreview: View {
	@State private var toast: ToastData?
	
	var body: some View {
		VStack(spacing: 20) {
			Button("Show Toast") {
				withAnimation {
					toast = ToastData(text: Text("Saved successfully"))
				}
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.toast($toast)
	}
}

#Preview {
	ToastPreview()
}
