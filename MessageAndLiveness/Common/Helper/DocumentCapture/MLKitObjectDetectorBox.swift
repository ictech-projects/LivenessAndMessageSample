//
//  MLKitObjectDetectorBox.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//
//  Wraps ML Kit Object Detection (streaming mode) and returns just the object
//  bounding boxes, so the document-alignment logic stays free of ML Kit types.
//

import CoreMedia
import UIKit

#if canImport(MLKitObjectDetection) && canImport(MLKitVision)
@preconcurrency import MLKitObjectDetection
@preconcurrency import MLKitVision

nonisolated final class MLKitObjectDetectorBox {

	private let detector: ObjectDetector
	private let lock = NSLock()
	private var isBusy = false

	init() {
		let options = ObjectDetectorOptions()
		options.detectorMode = .stream
		options.shouldEnableClassification = false
		options.shouldEnableMultipleObjects = false
		detector = ObjectDetector.objectDetector(options: options)
	}

	/// Detects objects and returns their bounding boxes (image coordinates).
	/// Skips the frame if a previous detection is still in flight.
	func process(
		_ sampleBuffer: CMSampleBuffer,
		orientation: UIImage.Orientation,
		completion: @escaping ([CGRect]) -> Void
	) {
		lock.lock()
		if isBusy { lock.unlock(); return }
		isBusy = true
		lock.unlock()

		let visionImage = VisionImage(buffer: sampleBuffer)
		visionImage.orientation = orientation

		detector.process(visionImage) { [weak self] objects, _ in
			self?.lock.lock()
			self?.isBusy = false
			self?.lock.unlock()
			completion((objects ?? []).map { $0.frame })
		}
	}
}
#endif
