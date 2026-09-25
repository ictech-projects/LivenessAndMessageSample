//
//  VisionTextRecognizer.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//

import QuartzCore
import UIKit
import Vision

nonisolated final class VisionTextRecognizer: OCRTextRecognizer {

	let engine: OCREngine = .vision

	func recognize(in image: UIImage) async throws -> OCRResult {
		let normalized = image.normalizedUp()
		guard let cgImage = normalized.cgImage else { throw OCRError.invalidImage }

		let start = CACurrentMediaTime()

		let request = VNRecognizeTextRequest()
		request.recognitionLevel = .accurate
		request.usesLanguageCorrection = true

		let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
		try handler.perform([request])

		let lines: [String] = (request.results ?? []).compactMap { observation in
			observation.topCandidates(1).first?.string
		}

		let durationMs = Int((CACurrentMediaTime() - start) * 1000)
		return OCRResult(engine: engine, lines: lines, durationMs: durationMs)
	}
}

enum OCRError: Error {
	case invalidImage
	case unavailable
}
