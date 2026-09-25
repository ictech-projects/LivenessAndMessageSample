//
//  IdentityVerificationViewModel.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//

import Combine
import CoreGraphics
import UIKit

/// Drives the post-auth identity gate: scan the ID (no details shown) → detect
/// its face → liveness check → match the live selfie against the ID. A passing
/// match calls `onVerified`; any hard failure calls `onFailed` (which returns
/// the user to the root / login).
@MainActor
final class IdentityVerificationViewModel: ObservableObject {

	@Published private(set) var documentThumbnail: UIImage?
	@Published private(set) var processingMessage = ""
	@Published var isProcessing = false
	@Published var isLivenessPresented = false
	@Published var alertMessage: String?

	var onVerified: (() -> Void)?
	var onFailed: (() -> Void)?

	private let cropper = MLKitFaceCropper()
	private let matcher: FaceMatcher = FaceMatcherFactory.make()

	private var documentFace: CGImage?
	private var selfie: CGImage?
	/// When true, dismissing the current alert returns to root (a hard failure);
	/// when false (e.g. no face on the ID) the user can just retake.
	private var alertIsTerminal = false

	var isAlertPresented: Bool {
		get { alertMessage != nil }
		set { if !newValue { dismissAlert() } }
	}

	// MARK: - Document capture (no details displayed)

	func handlePickedDocument(_ image: UIImage) {
		documentThumbnail = image
		Task { await detectFace(in: image) }
	}

	private func detectFace(in image: UIImage) async {
		isProcessing = true
		processingMessage = "Reading the document…"
		defer { isProcessing = false }

		do {
			documentFace = try await cropper.faceCrop(from: image, noFace: .noFaceInDocument)
			isLivenessPresented = true            // straight to liveness — no detail screen
		} catch {
			documentThumbnail = nil
			present(message(for: error), terminal: false)   // no face → let them retake
		}
	}

	// MARK: - Liveness

	func livenessSucceeded(selfie: CGImage?) {
		isLivenessPresented = false
		self.selfie = selfie
		Task { await runMatch() }
	}

	func livenessCancelled() {
		isLivenessPresented = false
		onFailed?()                                // backed out → return to root
	}

	// MARK: - Match

	private func runMatch() async {
		guard let documentFace, let selfie else {
			onFailed?()
			return
		}

		isProcessing = true
		processingMessage = "Verifying your identity…"
		defer { isProcessing = false }

		let selfieFace = (try? await cropper.faceCrop(
			from: UIImage(cgImage: selfie),
			noFace: .noFaceInSelfie
		)) ?? selfie

		do {
			let result = try await matcher.match(documentFace: documentFace, selfieFace: selfieFace)
			#if DEBUG
			print("🧑‍🤝‍🧑 face match — matcher:\(result.matcherName) similarity:\(String(format: "%.3f", result.similarity)) threshold:\(result.threshold) match:\(result.isMatch)")
			#endif
			if result.isMatch {
				onVerified?()
			} else {
				present("Your face doesn't match the ID photo. Please sign in and try again.", terminal: true)
			}
		} catch {
			present(message(for: error), terminal: true)
		}
	}

	// MARK: - Cancel / alerts

	func cancel() {
		onFailed?()
	}

	private func present(_ message: String, terminal: Bool) {
		alertIsTerminal = terminal
		alertMessage = message
	}

	private func dismissAlert() {
		let terminal = alertIsTerminal
		alertMessage = nil
		alertIsTerminal = false
		if terminal { onFailed?() }
	}

	private func message(for error: Error) -> String {
		(error as? FaceMatchError)?.errorDescription ?? error.localizedDescription
	}
}
