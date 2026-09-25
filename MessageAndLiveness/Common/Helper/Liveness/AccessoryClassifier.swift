//
//  AccessoryClassifier.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 23/09/26.
//

import CoreVideo
import ImageIO

/// Confidence (0...1) that the face in a frame is wearing each accessory type.
struct AccessoryVerdict: Equatable {
	let glasses: Float
	let hat: Float
	let mask: Float
	/// Top raw labels + scores, for on-device threshold calibration (DEBUG).
	let topLabels: [String]

	nonisolated static let none = AccessoryVerdict(glasses: 0, hat: 0, mask: 0, topLabels: [])
}

/// A "dedicated model" stage that classifies accessories on a camera frame.
///
/// The default implementation (`VisionAccessoryClassifier`) uses Apple's
/// built-in image classifier — no bundled model required. A stricter,
/// custom-trained CoreML model can be dropped in behind this same protocol
/// without touching the liveness pipeline.
protocol AccessoryClassifier: AnyObject, Sendable {
	nonisolated func classify(
		_ pixelBuffer: CVPixelBuffer,
		orientation: CGImagePropertyOrientation,
		completion: @escaping (AccessoryVerdict?) -> Void
	)
}
