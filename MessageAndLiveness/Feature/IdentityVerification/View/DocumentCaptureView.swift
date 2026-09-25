//
//  DocumentCaptureView.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//

import SwiftUI
import UIKit

/// Live document-capture screen. ML Kit Object Detection drives the alignment
/// guide; the frame auto-captures once the document is held steady in the box.
struct DocumentCaptureView: View {

	@StateObject private var camera = DocumentCaptureManager()
	@Environment(\.openURL) private var openURL

	let onCapture: (UIImage) -> Void
	let onCancel: () -> Void

	@State private var didCapture = false

	// ID card aspect ratio (ISO/IEC 7810 ID-1 ≈ 1.586:1).
	private let guideAspect: CGFloat = 1.586

	var body: some View {
		ZStack {
			Color.black.ignoresSafeArea()

			if camera.setupState == .denied || camera.setupState == .failed {
				unavailable
			} else {
				CameraPreviewView(session: camera.session, mirrored: false)
					.ignoresSafeArea()

				guideOverlay

				VStack {
					topBar
					Spacer()
					controls
				}
				.padding(.horizontal, 20)
				.padding(.bottom, 32)
			}
		}
		.task { await camera.start() }
		.onDisappear { camera.stop() }
		.onChange(of: camera.readyToCapture) { _, ready in
			if ready { capture() }
		}
	}

	private var guideColor: Color {
		camera.alignment.isAligned ? .successMain : .white.opacity(0.85)
	}

	private var guideOverlay: some View {
		GeometryReader { geometry in
			let width = geometry.size.width * 0.86
			let height = width / guideAspect

			RoundedRectangle(cornerRadius: 18)
				.stroke(guideColor, style: StrokeStyle(lineWidth: 3, dash: camera.alignment.isAligned ? [] : [10, 8]))
				.frame(width: width, height: height)
				.position(x: geometry.size.width / 2, y: geometry.size.height / 2)
				.animation(.easeInOut(duration: 0.2), value: camera.alignment)
		}
		.ignoresSafeArea()
	}

	private var topBar: some View {
		HStack {
			Button {
				onCancel()
			} label: {
				Image(systemName: "xmark")
					.font(.system(size: 16, weight: .bold))
					.foregroundStyle(.white)
					.frame(width: 40, height: 40)
					.background(Circle().fill(.white.opacity(0.16)))
			}
			.accessibilityLabel("Cancel")

			Spacer()

			Text("Scan your ID")
				.font(.baseStyle(size: 16, weight: .bold))
				.foregroundStyle(.white)

			Spacer()
			Color.clear.frame(width: 40, height: 40)
		}
		.padding(.top, 8)
	}

	private var controls: some View {
		VStack(spacing: 20) {
			Text(camera.alignment.message)
				.font(.baseStyle(size: 16, weight: .medium))
				.foregroundStyle(.white)
				.padding(.horizontal, 16)
				.padding(.vertical, 10)
				.background(Capsule().fill(.black.opacity(0.4)))

			Button {
				capture()
			} label: {
				ZStack {
					Circle().stroke(.white, lineWidth: 4).frame(width: 74, height: 74)
					Circle().fill(camera.alignment.isAligned ? Color.successMain : .white).frame(width: 60, height: 60)
				}
			}
			.disabled(!camera.alignment.isAligned)
			.opacity(camera.alignment.isAligned ? 1 : 0.5)
			.accessibilityLabel("Capture document")
		}
	}

	private var unavailable: some View {
		VStack(spacing: 20) {
			Image(systemName: "video.slash.fill")
				.font(.system(size: 48))
				.foregroundStyle(.white.opacity(0.9))

			Text(camera.setupState == .denied ? "Camera access needed" : "Camera unavailable")
				.font(.baseStyle(size: 20, weight: .bold))
				.foregroundStyle(.white)

			VStack(spacing: 12) {
				if camera.setupState == .denied {
					PrimaryButton(size: .medium, action: openSettings) {
						Text("Open Settings")
					}
				}
				#if targetEnvironment(simulator)
				PrimaryButton(size: .medium, action: pickPlaceholder) {
					Text("Use library (Simulator)")
				}
				#endif
				Button("Cancel", action: onCancel)
					.font(.baseStyle(size: 16, weight: .medium))
					.foregroundStyle(.white)
			}
			.padding(.top, 8)
		}
		.padding(28)
	}

	private func capture() {
		guard !didCapture, let cgImage = camera.snapshot() else { return }
		didCapture = true
		camera.stop()
		onCapture(UIImage(cgImage: cgImage))
	}

	private func openSettings() {
		guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
		openURL(url)
	}

	#if targetEnvironment(simulator)
	private func pickPlaceholder() {
		// No camera on the Simulator — bail out so the caller can offer the
		// photo-library picker instead.
		onCancel()
	}
	#endif
}
