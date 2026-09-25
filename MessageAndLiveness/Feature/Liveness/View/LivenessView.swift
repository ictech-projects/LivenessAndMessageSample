//
//  LivenessView.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import SwiftUI
import UIKit

/// Full-screen active-liveness experience: live front camera, a focus ring,
/// and a sequence of randomized challenges (blink / smile / turn).
struct LivenessView: View {

	@StateObject private var viewModel: LivenessViewModel
	@Environment(\.openURL) private var openURL

	private let circleDiameter: CGFloat = 300

	init(
		challenges: [LivenessChallenge] = LivenessChallenge.randomSequence(),
		onSuccess: @escaping (CGImage?) -> Void,
		onCancel: @escaping () -> Void
	) {
		let model = LivenessViewModel(challenges: challenges)
		model.onSuccess = onSuccess
		model.onCancel = onCancel
		_viewModel = StateObject(wrappedValue: model)
	}

	var body: some View {
		ZStack {
			Color.black.ignoresSafeArea()

			if viewModel.isCameraDenied || viewModel.isCameraFailed {
				CameraUnavailableView(
					isDenied: viewModel.isCameraDenied,
					onOpenSettings: { openSettings() },
					onCancel: { viewModel.cancel() },
					onSimulatorSkip: simulatorSkip
				)
			} else {
				cameraExperience
			}

			if viewModel.phase == .success {
				LivenessSuccessOverlay()
					.transition(.opacity.combined(with: .scale))
			}
		}
		.animation(.spring(duration: 0.4), value: viewModel.phase)
		.animation(.easeInOut(duration: 0.25), value: viewModel.faceInFrame)
		.task {
			await viewModel.onAppear()
		}
		.onDisappear {
			viewModel.onDisappear()
		}
	}

	private var cameraExperience: some View {
		ZStack {
			CameraPreviewView(session: viewModel.camera.session)
				.ignoresSafeArea()

			// Scrim hole and ring live in the SAME full-screen space so they are
			// centered on exactly the same point (otherwise the ring centers in
			// the safe area while the hole centers on the full screen).
			ZStack {
				Rectangle()
					.fill(Color.black.opacity(0.55))
					.reverseMask {
						Circle()
							.frame(width: circleDiameter, height: circleDiameter)
					}

				LivenessRing(
					diameter: circleDiameter,
					isActive: viewModel.faceInFrame,
					isComplete: viewModel.phase == .success
				)
			}
			.ignoresSafeArea()

			VStack(spacing: 0) {
				topBar
				Spacer()
				promptSection
			}
			.padding(.horizontal, 20)
			.padding(.bottom, 32)
		}
	}

	private var topBar: some View {
		HStack {
			Button {
				viewModel.cancel()
			} label: {
				Image(systemName: "xmark")
					.font(.system(size: 16, weight: .bold))
					.foregroundStyle(.white)
					.frame(width: 40, height: 40)
					.background(Circle().fill(.white.opacity(0.16)))
			}
			.accessibilityLabel("Close")

			Spacer()

			Text("Liveness Check")
				.font(.baseStyle(size: 16, weight: .bold))
				.foregroundStyle(.white)

			Spacer()

			// Balances the leading close button so the title stays centered.
			Color.clear.frame(width: 40, height: 40)
		}
		.padding(.top, 8)
	}

	private var promptSection: some View {
		VStack(spacing: 20) {
			LivenessProgressDots(
				total: viewModel.challenges.count,
				completed: viewModel.currentIndex
			)

			ChallengePromptCard(
				iconName: viewModel.currentChallenge?.systemImageName ?? "face.dashed",
				message: viewModel.statusText,
				isSuccess: viewModel.phase == .success,
				isWarning: viewModel.showsAccessoryWarning
			)
		}
	}

	private func openSettings() {
		guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
		openURL(url)
	}

	/// On the Simulator (no camera) this offers a way to pass the check so the
	/// auth flow is testable; `nil` — and therefore hidden — on real devices.
	private var simulatorSkip: (() -> Void)? {
		#if targetEnvironment(simulator)
		return { viewModel.simulatePass() }
		#else
		return nil
		#endif
	}
}

// MARK: - Focus ring

private struct LivenessRing: View {
	let diameter: CGFloat
	let isActive: Bool
	let isComplete: Bool

	@State private var pulse = false

	private var ringColor: Color {
		if isComplete { return .successMain }
		return isActive ? .brandSecondary : .white.opacity(0.5)
	}

	var body: some View {
		Circle()
			.stroke(ringColor, lineWidth: 4)
			.frame(width: diameter, height: diameter)
			.overlay {
				Circle()
					.stroke(ringColor.opacity(0.35), lineWidth: 12)
					.scaleEffect(pulse && isActive && !isComplete ? 1.06 : 1)
					.opacity(pulse && isActive && !isComplete ? 0 : 0.6)
					.frame(width: diameter, height: diameter)
			}
			.animation(.easeOut(duration: 1.1).repeatForever(autoreverses: false), value: pulse)
			.onAppear { pulse = true }
	}
}

// MARK: - Prompt card

private struct ChallengePromptCard: View {
	let iconName: String
	let message: String
	let isSuccess: Bool
	var isWarning: Bool = false

	private var symbol: String {
		if isSuccess { return "checkmark.seal.fill" }
		if isWarning { return "eyeglasses" }
		return iconName
	}

	private var accent: Color {
		if isSuccess { return .successMain }
		if isWarning { return .warningMain }
		return .brandSecondary
	}

	var body: some View {
		HStack(spacing: 14) {
			Image(systemName: symbol)
				.font(.system(size: 22, weight: .semibold))
				.foregroundStyle(accent)
				.frame(width: 44, height: 44)
				.background(Circle().fill(.white.opacity(0.14)))

			Text(message)
				.font(.baseStyle(size: 16, weight: .medium))
				.foregroundStyle(.white)
				.frame(maxWidth: .infinity, alignment: .leading)
				.contentTransition(.opacity)
		}
		.padding(16)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(.black.opacity(0.35))
				.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
		)
		.animation(.easeInOut(duration: 0.2), value: message)
	}
}

// MARK: - Progress dots

private struct LivenessProgressDots: View {
	let total: Int
	let completed: Int

	var body: some View {
		HStack(spacing: 8) {
			ForEach(0..<max(total, 1), id: \.self) { index in
				Capsule()
					.fill(index < completed ? Color.successMain : Color.white.opacity(0.35))
					.frame(width: index < completed ? 24 : 16, height: 6)
					.animation(.spring(duration: 0.3), value: completed)
			}
		}
	}
}

// MARK: - Success overlay

private struct LivenessSuccessOverlay: View {
	var body: some View {
		ZStack {
			Color.black.opacity(0.6).ignoresSafeArea()

			VStack(spacing: 16) {
				Image(systemName: "checkmark.circle.fill")
					.font(.system(size: 72))
					.foregroundStyle(.successMain)

				Text("Verified")
					.font(.baseStyle(size: 22, weight: .bold))
					.foregroundStyle(.white)
			}
		}
	}
}

// MARK: - Camera unavailable

private struct CameraUnavailableView: View {
	let isDenied: Bool
	let onOpenSettings: () -> Void
	let onCancel: () -> Void
	var onSimulatorSkip: (() -> Void)? = nil

	var body: some View {
		VStack(spacing: 20) {
			Image(systemName: "video.slash.fill")
				.font(.system(size: 48))
				.foregroundStyle(.white.opacity(0.9))

			Text(isDenied ? "Camera access needed" : "Camera unavailable")
				.font(.baseStyle(size: 20, weight: .bold))
				.foregroundStyle(.white)

			Text(isDenied
				 ? "Enable camera access in Settings so we can verify it's really you."
				 : "We couldn't start the camera on this device.")
				.font(.baseStyle(size: 14, weight: .regular))
				.foregroundStyle(.white.opacity(0.75))
				.multilineTextAlignment(.center)

			VStack(spacing: 12) {
				if isDenied {
					PrimaryButton(size: .medium, action: onOpenSettings) {
						Text("Open Settings")
					}
				}

				if let onSimulatorSkip {
					PrimaryButton(size: .medium, action: onSimulatorSkip) {
						Text("Simulate pass (Simulator)")
					}
				}

				Button(action: onCancel) {
					Text("Cancel")
						.font(.baseStyle(size: 16, weight: .medium))
						.foregroundStyle(.white)
				}
			}
			.padding(.top, 8)
		}
		.padding(28)
	}
}

// MARK: - Reverse mask helper

private extension View {
	/// Punches the given shape out of the receiver (inverse of `.mask`).
	@ViewBuilder
	func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
		self.mask {
			Rectangle()
				.overlay {
					mask()
						.blendMode(.destinationOut)
				}
				.compositingGroup()
		}
	}
}

#Preview {
	LivenessView(onSuccess: { _ in }, onCancel: {})
}
