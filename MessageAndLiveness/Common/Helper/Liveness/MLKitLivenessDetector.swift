//
//  MLKitLivenessDetector.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//
//  Uses Google ML Kit Face Detection (via the d-date/google-mlkit-swiftpm
//  package). Face detection additionally requires `GoogleMVFaceDetectorResources.bundle`,
//  which SPM cannot vendor automatically — download it from the package's
//  releases page and add it to the app target, otherwise no faces are returned
//  at runtime. See ONBOARDING notes in the PR description.
//

import AVFoundation
import CoreMedia
import ImageIO
import QuartzCore
import UIKit

#if canImport(MLKitFaceDetection) && canImport(MLKitVision)
@preconcurrency import MLKitFaceDetection
@preconcurrency import MLKitVision

nonisolated final class MLKitLivenessDetector: LivenessDetector, @unchecked Sendable {

	private let faceDetector: FaceDetector

	// Throttle: only one frame in flight at a time so we don't queue up work
	// faster than the model can consume it.
	private let lock = NSLock()
	private var isBusy = false

	// Dedicated accessory model (Apple Vision by default), run on a throttled
	// cadence since it's heavier than face detection. The latest verdict is
	// cached and attached to every emitted FaceSignals.
	private let accessory: AccessoryClassifier
	private let accessoryLock = NSLock()
	private var cachedVerdict: AccessoryVerdict?
	private var lastAccessoryAt: CFTimeInterval = 0
	private let accessoryInterval: CFTimeInterval = 0.35

	init(accessory: AccessoryClassifier = VisionAccessoryClassifier()) {
		self.accessory = accessory
		let options = FaceDetectorOptions()
		options.performanceMode = .fast
		options.landmarkMode = .none
		options.contourMode = .none
		options.classificationMode = .all   // eyes-open + smiling probabilities
		options.minFaceSize = 0.15
		faceDetector = FaceDetector.faceDetector(options: options)
	}

	func detect(
		in sampleBuffer: CMSampleBuffer,
		orientation: UIImage.Orientation,
		completion: @escaping (FaceSignals?) -> Void
	) {
		guard beginIfIdle() else { return }

		let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
		// The camera buffer is landscape; compare the face against the SHORTER
		// side, which maps to the portrait preview width the user actually sees.
		let referenceSide: CGFloat = pixelBuffer.map {
			CGFloat(min(CVPixelBufferGetWidth($0), CVPixelBufferGetHeight($0)))
		} ?? 0

		// Kick the accessory model on a throttled cadence (runs synchronously
		// here on the sample queue, so the pixel buffer stays valid).
		if let pixelBuffer {
			refreshAccessoryIfDue(pixelBuffer, cgOrientation(from: orientation))
		}
		let verdict = currentVerdict()

		let visionImage = VisionImage(buffer: sampleBuffer)
		visionImage.orientation = orientation

		faceDetector.process(visionImage) { [weak self] faces, error in
			self?.endBusy()

			guard error == nil, let faces, !faces.isEmpty else {
				completion(.noFace)
				return
			}

			// Track the largest (closest) face — that's the one being verified.
			let face = faces.max { $0.frame.width < $1.frame.width } ?? faces[0]

			let signals = FaceSignals(
				hasFace: true,
				multipleFaces: faces.count > 1,
				leftEyeOpen: face.hasLeftEyeOpenProbability ? Float(face.leftEyeOpenProbability) : nil,
				rightEyeOpen: face.hasRightEyeOpenProbability ? Float(face.rightEyeOpenProbability) : nil,
				smiling: face.hasSmilingProbability ? Float(face.smilingProbability) : nil,
				headYaw: face.hasHeadEulerAngleY ? Float(face.headEulerAngleY) : nil,
				headRoll: face.hasHeadEulerAngleZ ? Float(face.headEulerAngleZ) : nil,
				faceBoxRatio: referenceSide > 0 ? Float(face.frame.width / referenceSide) : nil,
				accessory: verdict
			)
			completion(signals)
		}
	}

	// MARK: - Accessory model

	private func currentVerdict() -> AccessoryVerdict? {
		accessoryLock.lock()
		defer { accessoryLock.unlock() }
		return cachedVerdict
	}

	private func refreshAccessoryIfDue(_ pixelBuffer: CVPixelBuffer, _ orientation: CGImagePropertyOrientation) {
		let now = CACurrentMediaTime()

		accessoryLock.lock()
		let due = now - lastAccessoryAt >= accessoryInterval
		if due { lastAccessoryAt = now }
		accessoryLock.unlock()

		guard due else { return }

		accessory.classify(pixelBuffer, orientation: orientation) { [weak self] verdict in
			guard let self, let verdict else { return }
			self.accessoryLock.lock()
			self.cachedVerdict = verdict
			self.accessoryLock.unlock()

			#if DEBUG
			if verdict.glasses > 0.1 || verdict.hat > 0.1 || verdict.mask > 0.1 {
				print("🕶️ accessory — glasses:\(verdict.glasses) hat:\(verdict.hat) mask:\(verdict.mask) top:\(verdict.topLabels)")
			}
			#endif
		}
	}

	private func cgOrientation(from orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
		switch orientation {
		case .up: return .up
		case .upMirrored: return .upMirrored
		case .down: return .down
		case .downMirrored: return .downMirrored
		case .left: return .left
		case .leftMirrored: return .leftMirrored
		case .right: return .right
		case .rightMirrored: return .rightMirrored
		@unknown default: return .up
		}
	}

	private func beginIfIdle() -> Bool {
		lock.lock()
		defer { lock.unlock() }
		if isBusy { return false }
		isBusy = true
		return true
	}

	private func endBusy() {
		lock.lock()
		isBusy = false
		lock.unlock()
	}
}
#endif
