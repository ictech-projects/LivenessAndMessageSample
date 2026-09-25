//
//  FaceMatchModels.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//

import Foundation

/// Outcome of comparing a document face against a live selfie.
struct FaceMatchResult: Equatable {
	/// Normalized similarity, 0...1 (higher = more likely the same person).
	let similarity: Float
	/// The matcher's pass threshold on `similarity`.
	let threshold: Float
	/// Human-readable matcher name (for UI/debug).
	let matcherName: String

	var isMatch: Bool { similarity >= threshold }

	/// Similarity as a 0–100 percentage for display.
	var percentage: Int { Int((similarity * 100).rounded()) }
}

enum FaceMatchError: LocalizedError, Equatable {
	case noFaceInDocument
	case noFaceInSelfie
	case matcherUnavailable
	case failed

	var errorDescription: String? {
		switch self {
		case .noFaceInDocument:
			return "We couldn't find a face on the ID photo. Retake a clear, well-lit photo of the document."
		case .noFaceInSelfie:
			return "We couldn't capture your face clearly. Please try the liveness check again."
		case .matcherUnavailable:
			return "Face matching isn't available on this device build."
		case .failed:
			return "Face matching failed. Please try again."
		}
	}
}
