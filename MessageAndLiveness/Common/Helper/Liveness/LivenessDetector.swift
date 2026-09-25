//
//  LivenessDetector.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import AVFoundation
import CoreMedia
import UIKit

/// Per-frame face measurements produced by a `LivenessDetector`.
///
/// Every value except `hasFace`/`multipleFaces` is optional because the
/// underlying model only emits it when confident. Probabilities are `0...1`;
/// `headYaw` is in degrees (negative = turned toward the user's right on a
/// mirrored front camera, positive = toward their left).
struct FaceSignals: Equatable {
	let hasFace: Bool
	let multipleFaces: Bool
	/// `nil` when the model couldn't classify the eye — a strong occlusion hint
	/// (sunglasses / glasses hiding the eyes).
	let leftEyeOpen: Float?
	let rightEyeOpen: Float?
	/// `nil` when the mouth couldn't be classified — hints a mask/cover.
	let smiling: Float?
	let headYaw: Float?
	/// Head roll (tilt) in degrees; used with yaw for a frontal-pose check.
	let headRoll: Float?
	/// Face width as a fraction of the frame width — a rough "how close" proxy.
	let faceBoxRatio: Float?
	/// Dedicated-model accessory scores (glasses/hat/mask), or `nil` if the
	/// classifier hasn't produced a verdict yet.
	let accessory: AccessoryVerdict?

	nonisolated static let noFace = FaceSignals(
		hasFace: false,
		multipleFaces: false,
		leftEyeOpen: nil,
		rightEyeOpen: nil,
		smiling: nil,
		headYaw: nil,
		headRoll: nil,
		faceBoxRatio: nil,
		accessory: nil
	)
}

/// Analyzes camera frames for face/liveness signals.
///
/// Implementations run off the main thread (on the camera's sample-buffer
/// queue) and must invoke `completion` for every frame they choose to process.
/// Frames they skip (e.g. while busy) should simply not call back.
protocol LivenessDetector: AnyObject, Sendable {
	nonisolated func detect(
		in sampleBuffer: CMSampleBuffer,
		orientation: UIImage.Orientation,
		completion: @escaping (FaceSignals?) -> Void
	)
}

/// Selects the concrete detector available at build time.
enum LivenessDetectorFactory {
	nonisolated static func make() -> LivenessDetector {
		#if canImport(MLKitFaceDetection) && canImport(MLKitVision)
		return MLKitLivenessDetector()
		#else
		#warning("MLKitFaceDetection is unavailable — liveness detection is stubbed out.")
		return UnavailableLivenessDetector()
		#endif
	}
}

/// Fallback used only if the ML Kit modules can't be imported, so the app
/// still builds. It reports no faces (liveness will never pass).
nonisolated final class UnavailableLivenessDetector: LivenessDetector {
	func detect(
		in sampleBuffer: CMSampleBuffer,
		orientation: UIImage.Orientation,
		completion: @escaping (FaceSignals?) -> Void
	) {
		completion(.noFace)
	}
}

enum CameraError: Error {
	case noFrontCamera
	case cannotAddInput
	case cannotAddOutput
}
