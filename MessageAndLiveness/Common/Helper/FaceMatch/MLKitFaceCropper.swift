//
//  MLKitFaceCropper.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//
//  Uses ML Kit Face Detection to locate the largest face in a still image
//  (an ID document photo or a selfie) and return a padded crop of it, ready to
//  feed the FaceMatcher. This is ML Kit's role in the identity flow — detection
//  and cropping (ML Kit cannot match/recognize faces).
//

import CoreGraphics
import UIKit

#if canImport(MLKitFaceDetection) && canImport(MLKitVision)
@preconcurrency import MLKitFaceDetection
@preconcurrency import MLKitVision

final class MLKitFaceCropper {

	private let detector: FaceDetector

	init() {
		let options = FaceDetectorOptions()
		options.performanceMode = .accurate
		options.landmarkMode = .none
		options.classificationMode = .none
		options.minFaceSize = 0.1
		detector = FaceDetector.faceDetector(options: options)
	}

	/// Detects the largest face and returns a padded crop. Throws `noFace` if
	/// none is found.
	func faceCrop(from image: UIImage, padding: CGFloat = 0.3, noFace: FaceMatchError) async throws -> CGImage {
		// Normalize to `.up`, scale 1 so ML Kit point coords map 1:1 to CGImage pixels.
		let normalized = image.normalizedUp()
		guard let cgImage = normalized.cgImage else { throw FaceMatchError.failed }

		let visionImage = VisionImage(image: normalized)
		visionImage.orientation = .up

		let faces: [Face] = try await withCheckedThrowingContinuation { continuation in
			detector.process(visionImage) { faces, error in
				if let error { continuation.resume(throwing: error) }
				else { continuation.resume(returning: faces ?? []) }
			}
		}

		guard let face = faces.max(by: { $0.frame.width < $1.frame.width }) else {
			throw noFace
		}

		let cropRect = paddedRect(
			face.frame,
			padding: padding,
			bounds: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
		)

		guard let cropped = cgImage.cropping(to: cropRect) else { throw FaceMatchError.failed }
		return cropped
	}

	private func paddedRect(_ rect: CGRect, padding: CGFloat, bounds: CGRect) -> CGRect {
		let dx = rect.width * padding
		let dy = rect.height * padding
		return rect.insetBy(dx: -dx, dy: -dy).integral.intersection(bounds)
	}
}
#else
final class MLKitFaceCropper {
	func faceCrop(from image: UIImage, padding: CGFloat = 0.3, noFace: FaceMatchError) async throws -> CGImage {
		throw FaceMatchError.matcherUnavailable
	}
}
#endif

extension UIImage {
	/// Redraws the image in `.up` orientation at scale 1, so pixel coordinates
	/// line up with points (removes EXIF-orientation surprises before cropping).
	nonisolated func normalizedUp() -> UIImage {
		if imageOrientation == .up && scale == 1 { return self }
		let format = UIGraphicsImageRendererFormat.default()
		format.scale = 1
		format.opaque = false
		let renderer = UIGraphicsImageRenderer(size: size, format: format)
		return renderer.image { _ in
			draw(in: CGRect(origin: .zero, size: size))
		}
	}
}
