//
//  VisionAccessoryClassifier.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 23/09/26.
//
//  Uses Apple Vision's built-in image classifier (`VNClassifyImageRequest`) as
//  the accessory-detection model. It ships with iOS — no model file to bundle
//  or download. Accuracy on a face crop is decent but not KYC-perfect; the
//  liveness thresholds are tunable and the top labels are logged in DEBUG so
//  they can be calibrated on-device. For guaranteed accuracy, swap in a
//  custom-trained CoreML model behind `AccessoryClassifier`.
//

import CoreVideo
import ImageIO
import Vision

nonisolated final class VisionAccessoryClassifier: AccessoryClassifier {

	func classify(
		_ pixelBuffer: CVPixelBuffer,
		orientation: CGImagePropertyOrientation,
		completion: @escaping (AccessoryVerdict?) -> Void
	) {
		let request = VNClassifyImageRequest()
		let handler = VNImageRequestHandler(
			cvPixelBuffer: pixelBuffer,
			orientation: orientation,
			options: [:]
		)

		do {
			try handler.perform([request])
		} catch {
			completion(nil)
			return
		}

		guard let observations = request.results else {
			completion(AccessoryVerdict.none)
			return
		}

		let relevant = observations.filter { $0.confidence > 0.02 }

		func score(matching keywords: [String]) -> Float {
			relevant
				.filter { obs in
					let id = obs.identifier.lowercased()
					return keywords.contains { id.contains($0) }
				}
				.map(\.confidence)
				.max() ?? 0
		}

		let glasses = score(matching: ["eyeglass", "glasses", "spectacle", "goggle", "sunglass"])
		let hat = score(matching: [
			"hat", "cap", "helmet", "sombrero", "beanie", "bonnet",
			"turban", "hood", "headgear", "fedora", "beret", "headscarf"
		])
		let mask = score(matching: ["mask", "respirator", "veil"])

		let top = observations
			.sorted { $0.confidence > $1.confidence }
			.prefix(6)
			.map { "\($0.identifier):\(String(format: "%.2f", $0.confidence))" }

		completion(
			AccessoryVerdict(
				glasses: glasses,
				hat: hat,
				mask: mask,
				topLabels: Array(top)
			)
		)
	}
}
