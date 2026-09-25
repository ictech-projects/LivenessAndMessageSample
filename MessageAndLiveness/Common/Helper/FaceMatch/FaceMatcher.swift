//
//  FaceMatcher.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//
//  ML Kit / Firebase ML has no face-recognition (matching) capability — it only
//  detects faces. So matching lives behind this protocol:
//    • default  : VisionFeaturePrintFaceMatcher (built-in, works with no model —
//                 a baseline, NOT identity-grade)
//    • drop-in  : CoreMLFaceMatcher (MobileFaceNet/ArcFace .mlmodelc) for real,
//                 identity-grade accuracy — selected automatically when present.
//

import CoreGraphics

protocol FaceMatcher: Sendable {
	var name: String { get }
	func match(documentFace: CGImage, selfieFace: CGImage) async throws -> FaceMatchResult
}

enum FaceMatcherFactory {
	/// Prefers a bundled CoreML face-recognition model; otherwise falls back to
	/// the built-in Vision baseline so the flow still works end-to-end.
	static func make() -> FaceMatcher {
		if let coreML = CoreMLFaceMatcher() {
			return coreML
		}
		return VisionFeaturePrintFaceMatcher()
	}
}
