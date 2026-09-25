//
//  MLKitTextRecognizer.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//

import QuartzCore
import UIKit

#if canImport(MLKitTextRecognition) && canImport(MLKitVision)
@preconcurrency import MLKitTextRecognition
@preconcurrency import MLKitVision

nonisolated final class MLKitTextRecognizer: OCRTextRecognizer, @unchecked Sendable {

	let engine: OCREngine = .mlKit

	/// The Latin text model bundle ML Kit loads at runtime. SPM can't embed it in
	/// a binary target, so the d-date package ships it as a loose bundle
	/// (`LatinOCRResources.bundle`) that the app must include — it's vendored in
	/// `Common/Resource/MLKit/`. Without it ML Kit throws an uncatchable
	/// NSException ("Invalid model path"), so availability is checked first.
	static var isAvailable: Bool {
		Bundle.main.url(forResource: "LatinOCRResources", withExtension: "bundle") != nil
	}

	// ML Kit's Latin-script text recognizer. Fully qualified because ML Kit also
	// exposes a type named `TextRecognizer`. Only instantiated by the factory
	// when `isAvailable` is true.
	private let recognizer = MLKitTextRecognition.TextRecognizer.textRecognizer(
		options: TextRecognizerOptions()
	)

	func recognize(in image: UIImage) async throws -> OCRResult {
		let normalized = image.normalizedUp()
		let visionImage = VisionImage(image: normalized)
		visionImage.orientation = .up

		let start = CACurrentMediaTime()

		let text: Text = try await withCheckedThrowingContinuation { continuation in
			recognizer.process(visionImage) { result, error in
				if let error { continuation.resume(throwing: error) }
				else if let result { continuation.resume(returning: result) }
				else { continuation.resume(throwing: OCRError.unavailable) }
			}
		}

		let lines = text.blocks
			.flatMap { $0.lines }
			.map { $0.text }

		let durationMs = Int((CACurrentMediaTime() - start) * 1000)
		return OCRResult(engine: engine, lines: lines, durationMs: durationMs)
	}
}
#else
nonisolated final class MLKitTextRecognizer: OCRTextRecognizer {
	let engine: OCREngine = .mlKit
	static var isAvailable: Bool { false }
	func recognize(in image: UIImage) async throws -> OCRResult {
		throw OCRError.unavailable
	}
}
#endif
