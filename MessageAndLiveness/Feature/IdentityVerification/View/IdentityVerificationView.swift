//
//  IdentityVerificationView.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//

import SwiftUI
import UIKit

/// Post-auth identity gate: scan the ID → liveness → face match. On success it
/// calls `onVerified`; on failure/cancel it calls `onFailed` (back to root).
/// No document details/OCR are shown — this only proves it's the same person.
struct IdentityVerificationView: View {

	@StateObject private var viewModel = IdentityVerificationViewModel()

	let onVerified: () -> Void
	let onFailed: () -> Void

	@State private var showPicker = false
	@State private var showDocumentCamera = false
	/// Held between capturing the ID and presenting liveness, so the document
	/// camera/sheet fully dismisses (and its session tears down) BEFORE the
	/// liveness camera starts — two AVCaptureSessions must not overlap.
	@State private var pendingDocument: UIImage?

	var body: some View {
		NavigationStack {
			ZStack {
				Color(.systemBackground).ignoresSafeArea()
				content
					.padding(24)

				if viewModel.isProcessing {
					LoadingOverlay(message: viewModel.processingMessage)
				}
			}
			.navigationTitle("Verify Identity")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button("Cancel") { viewModel.cancel() }
				}
			}
			.sheet(isPresented: $showPicker, onDismiss: presentLivenessForPendingDocument) {
				ImagePicker(sourceType: .photoLibrary) { image in
					pendingDocument = image
				}
				.ignoresSafeArea()
			}
			.fullScreenCover(isPresented: $showDocumentCamera, onDismiss: presentLivenessForPendingDocument) {
				DocumentCaptureView(
					onCapture: { image in
						pendingDocument = image
						showDocumentCamera = false
					},
					onCancel: { showDocumentCamera = false }
				)
			}
			.fullScreenCover(isPresented: $viewModel.isLivenessPresented) {
				LivenessView(
					onSuccess: { selfie in viewModel.livenessSucceeded(selfie: selfie) },
					onCancel: { viewModel.livenessCancelled() }
				)
			}
			.baseAlert(
				isPresented: $viewModel.isAlertPresented,
				type: .error,
				title: "Verification issue",
				message: viewModel.alertMessage ?? "",
				confirmButtonColor: (text: .white, background: .brandSecondary, stroke: .clear),
				confirmLabel: Text("OK"),
				confirmAction: { viewModel.isAlertPresented = false }
			)
			.onAppear {
				viewModel.onVerified = onVerified
				viewModel.onFailed = onFailed
			}
		}
	}

	/// Runs after the document camera/sheet has fully dismissed: detect the ID
	/// face and (on success) present the liveness camera.
	private func presentLivenessForPendingDocument() {
		guard let image = pendingDocument else { return }
		pendingDocument = nil
		viewModel.handlePickedDocument(image)
	}

	private var content: some View {
		VStack(spacing: 28) {
			Spacer()

			Image(systemName: "person.text.rectangle")
				.font(.system(size: 44))
				.foregroundStyle(.brandSecondary)
				.frame(width: 108, height: 108)
				.background(Circle().fill(Color.brandSecondary.opacity(0.12)))

			VStack(spacing: 10) {
				Text("Verify it's you")
					.font(.baseStyle(size: 22, weight: .bold))
					.foregroundStyle(.neutral90)

				Text("Scan your ID (KTP, passport, or other government ID), then complete a quick liveness check. We only use it to confirm your identity.")
					.font(.baseStyle(size: 15, weight: .regular))
					.foregroundStyle(.neutral70)
					.multilineTextAlignment(.center)
			}

			Spacer()

			VStack(spacing: 12) {
				if ImagePicker.isCameraAvailable {
					PrimaryButton(size: .large, action: { showDocumentCamera = true }) {
						HStack(spacing: 8) {
							Image(systemName: "camera.fill")
							Text("Scan with camera")
						}
					}
				}

				OutlinedButton(
					action: { showPicker = true },
					title: Text("Choose from library"),
					leftImage: nil
				)
			}
		}
	}
}

#Preview {
	IdentityVerificationView(onVerified: {}, onFailed: {})
}
