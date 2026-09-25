//
//  VisionFeaturePrintFaceMatcher.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//
//  Baseline matcher using Apple Vision's generic image feature print
//  (`VNGenerateImageFeaturePrintRequest`). Works on-device with NO model file,
//  so the identity flow is demonstrable immediately. IMPORTANT: this is a
//  general image-similarity signal, not a face-recognition embedding — treat it
//  as a baseline and swap in `CoreMLFaceMatcher` (MobileFaceNet) for real KYC.
//

import CoreGraphics
import Vision

nonisolated final class VisionFeaturePrintFaceMatcher: FaceMatcher {

	let name = "Vision FeaturePrint (baseline)"

	/// Similarity pass threshold. Deliberately conservative; calibrate on-device.
	private let threshold: Float = 0.55

	func match(documentFace: CGImage, selfieFace: CGImage) async throws -> FaceMatchResult {
		let a = try featurePrint(documentFace)
		let b = try featurePrint(selfieFace)

		var distance: Float = 0
		try a.computeDistance(&distance, to: b)

		// Feature-print distance is an L2 metric (0 = identical, grows apart).
		// Map it into a 0...1 similarity for display/threshold.
		let similarity = max(0, min(1, 1 - distance))

		return FaceMatchResult(
			similarity: similarity,
			threshold: threshold,
			matcherName: name
		)
	}

	private func featurePrint(_ image: CGImage) throws -> VNFeaturePrintObservation {
		let request = VNGenerateImageFeaturePrintRequest()
		let handler = VNImageRequestHandler(cgImage: image, options: [:])
		try handler.perform([request])

		guard let observation = request.results?.first as? VNFeaturePrintObservation else {
			throw FaceMatchError.failed
		}
		return observation
	}
}
