//
//  TextRecognizer.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//
//  Two interchangeable OCR engines run on the same captured ID photo so their
//  output can be compared side by side, and either can be selected for the task:
//    • MLKitTextRecognizer  — Google ML Kit Text Recognition (on-device)
//    • VisionTextRecognizer — Apple Vision VNRecognizeTextRequest (on-device)
//

import Foundation
import UIKit

/// Which OCR engine produced (or should produce) a result.
enum OCREngine: String, CaseIterable, Identifiable {
	case mlKit = "ML Kit"
	case vision = "Apple Vision"

	var id: String { rawValue }
}

/// Result of running one OCR engine on an image.
struct OCRResult: Equatable {
	let engine: OCREngine
	let lines: [String]
	/// Wall-clock time the recognition took, in milliseconds.
	let durationMs: Int

	var fullText: String { lines.joined(separator: "\n") }
	var isEmpty: Bool { lines.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty } }
}

protocol OCRTextRecognizer: Sendable {
	var engine: OCREngine { get }
	nonisolated func recognize(in image: UIImage) async throws -> OCRResult
}

enum TextRecognizerFactory {
	nonisolated static func make(_ engine: OCREngine) -> OCRTextRecognizer {
		switch engine {
		case .mlKit: return MLKitTextRecognizer()
		case .vision: return VisionTextRecognizer()
		}
	}

	/// Engines whose model is actually available in this build. Apple Vision is
	/// always available; ML Kit only when its Latin text model bundle is present
	/// (otherwise it would crash with an uncatchable "Invalid model path").
	nonisolated static func availableEngines() -> [OCREngine] {
		OCREngine.allCases.filter { engine in
			switch engine {
			case .vision: return true
			case .mlKit: return MLKitTextRecognizer.isAvailable
			}
		}
	}

	/// Recognizers for every available engine (used to run them side by side).
	nonisolated static func makeAll() -> [OCRTextRecognizer] {
		availableEngines().map(make)
	}
}
