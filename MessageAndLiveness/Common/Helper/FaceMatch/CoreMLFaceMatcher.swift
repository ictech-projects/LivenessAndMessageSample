//
//  CoreMLFaceMatcher.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//
//  Identity-grade matcher: runs a bundled face-recognition CoreML model
//  (FaceNet / MobileFaceNet / ArcFace) to produce an embedding per face, then
//  compares them with cosine similarity.
//
//  The model is loaded dynamically, so this file compiles even when no model is
//  bundled — `init?` returns nil and the factory falls back to the Vision
//  baseline. It drives the model DIRECTLY through `MLModel` (not Vision), so it
//  supports models whose input is a raw `MLMultiArray` (e.g. FaceNet exported
//  with a `[1,160,160,3]` input), which the Vision `VNCoreMLModel` path rejects.
//

import CoreGraphics
import CoreML
import UIKit

nonisolated final class CoreMLFaceMatcher: FaceMatcher, @unchecked Sendable {

	let name = "CoreML face embedding"

	/// Cosine-similarity pass threshold. Kept permissive so the same person still
	/// matches across a large age gap (child ID photo vs adult selfie); raise it
	/// if you see false accepts. Calibrate against the `🧑‍🤝‍🧑 face match` DEBUG log.
	private let threshold: Float = 0.36

	private let model: MLModel
	private let inputName: String
	private let outputName: String
	private let inputWidth: Int
	private let inputHeight: Int
	/// True for NCHW `[1,3,H,W]`, false for NHWC `[1,H,W,3]`.
	private let channelsFirst: Bool

	init?() {
		guard let url = Self.findModelURL() else {
			#if DEBUG
			print("ℹ️ CoreMLFaceMatcher: no bundled face model (.mlmodelc) found — using Vision baseline.")
			#endif
			return nil
		}

		guard let mlModel = try? MLModel(contentsOf: url) else {
			#if DEBUG
			print("⚠️ CoreMLFaceMatcher: found \(url.lastPathComponent) but couldn't load it.")
			#endif
			return nil
		}

		let description = mlModel.modelDescription
		guard
			let input = description.inputDescriptionsByName.first,
			let output = description.outputDescriptionsByName.first,
			let shape = input.value.multiArrayConstraint?.shape as? [Int],
			shape.count == 4
		else {
			#if DEBUG
			print("⚠️ CoreMLFaceMatcher: \(url.lastPathComponent) has an unexpected input (need a 4-D MultiArray). Inputs: \(description.inputDescriptionsByName.keys)")
			#endif
			return nil
		}

		self.model = mlModel
		self.inputName = input.key
		self.outputName = output.key

		if shape[1] == 3 {                 // [1, 3, H, W]
			channelsFirst = true
			inputHeight = shape[2]
			inputWidth = shape[3]
		} else {                           // [1, H, W, 3]
			channelsFirst = false
			inputHeight = shape[1]
			inputWidth = shape[2]
		}

		#if DEBUG
		print("✅ CoreMLFaceMatcher: loaded \(url.lastPathComponent) — input '\(inputName)' \(shape), output '\(outputName)'")
		#endif
	}

	func match(documentFace: CGImage, selfieFace: CGImage) async throws -> FaceMatchResult {
		let a = try embedding(for: documentFace)
		let b = try embedding(for: selfieFace)
		let similarity = Self.cosineSimilarity(a, b)

		return FaceMatchResult(
			similarity: max(0, min(1, similarity)),
			threshold: threshold,
			matcherName: name
		)
	}

	// MARK: - Inference

	private func embedding(for image: CGImage) throws -> [Float] {
		guard let pixels = Self.resizedRGBA(image, width: inputWidth, height: inputHeight) else {
			throw FaceMatchError.failed
		}

		let array = try MLMultiArray(
			shape: channelsFirst
				? [1, 3, inputHeight, inputWidth] as [NSNumber]
				: [1, inputHeight, inputWidth, 3] as [NSNumber],
			dataType: .float32
		)
		let ptr = array.dataPointer.bindMemory(to: Float32.self, capacity: array.count)

		// FaceNet normalization: (pixel - 127.5) / 128 → roughly [-1, 1].
		for y in 0..<inputHeight {
			for x in 0..<inputWidth {
				let p = (y * inputWidth + x) * 4
				let r = (Float(pixels[p + 0]) - 127.5) / 128.0
				let g = (Float(pixels[p + 1]) - 127.5) / 128.0
				let b = (Float(pixels[p + 2]) - 127.5) / 128.0
				if channelsFirst {
					ptr[(0 * inputHeight + y) * inputWidth + x] = r
					ptr[(1 * inputHeight + y) * inputWidth + x] = g
					ptr[(2 * inputHeight + y) * inputWidth + x] = b
				} else {
					let base = (y * inputWidth + x) * 3
					ptr[base + 0] = r
					ptr[base + 1] = g
					ptr[base + 2] = b
				}
			}
		}

		let provider = try MLDictionaryFeatureProvider(
			dictionary: [inputName: MLFeatureValue(multiArray: array)]
		)
		let prediction = try model.prediction(from: provider)

		guard let embedding = prediction.featureValue(for: outputName)?.multiArrayValue else {
			throw FaceMatchError.failed
		}

		var vector = [Float](repeating: 0, count: embedding.count)
		let ePtr = embedding.dataPointer.bindMemory(to: Float32.self, capacity: embedding.count)
		if embedding.dataType == .float32 {
			for i in 0..<embedding.count { vector[i] = ePtr[i] }
		} else {
			for i in 0..<embedding.count { vector[i] = embedding[i].floatValue }
		}
		return vector
	}

	/// Draws the image into a `width`x`height` RGBA8 buffer (top-left origin).
	private static func resizedRGBA(_ image: CGImage, width: Int, height: Int) -> [UInt8]? {
		var buffer = [UInt8](repeating: 0, count: width * height * 4)
		guard let context = CGContext(
			data: &buffer,
			width: width,
			height: height,
			bitsPerComponent: 8,
			bytesPerRow: width * 4,
			space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
		) else {
			return nil
		}
		context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
		return buffer
	}

	/// Finds a compiled face-recognition model in the bundle, tolerant of the
	/// file's casing/name (e.g. `facenet.mlmodel` → `facenet.mlmodelc`).
	private static func findModelURL() -> URL? {
		let preferred = ["mobilefacenet", "arcface", "facenet", "faceembedding"]
		let urls = Bundle.main.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil) ?? []

		func stem(_ url: URL) -> String { url.deletingPathExtension().lastPathComponent.lowercased() }

		if let match = urls.first(where: { preferred.contains(stem($0)) }) { return match }
		if let faceish = urls.first(where: { stem($0).contains("face") || stem($0).contains("arc") }) { return faceish }
		return urls.count == 1 ? urls.first : nil
	}

	private static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
		guard a.count == b.count, !a.isEmpty else { return 0 }
		var dot: Float = 0, normA: Float = 0, normB: Float = 0
		for i in 0..<a.count {
			dot += a[i] * b[i]
			normA += a[i] * a[i]
			normB += b[i] * b[i]
		}
		let denom = normA.squareRoot() * normB.squareRoot()
		guard denom > 0 else { return 0 }
		return dot / denom
	}
}
