//
//  CameraSessionManager.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

@preconcurrency import AVFoundation
import Combine
import CoreMedia
import UIKit

/// Owns the front-camera `AVCaptureSession`, pipes frames through a
/// `LivenessDetector`, and republishes the resulting `FaceSignals` on the main
/// actor for the ViewModel to consume.
@MainActor
final class CameraSessionManager: ObservableObject {

	enum SetupState: Equatable {
		case idle
		case configuring
		case ready
		case denied
		case failed
	}

	@Published private(set) var setupState: SetupState = .idle

	let session = AVCaptureSession()

	/// Delivered on the main actor, one per processed frame.
	var onSignals: ((FaceSignals) -> Void)?

	private let videoOutput = AVCaptureVideoDataOutput()
	/// Serialises all session control (configure/start/stop) — separate from the
	/// frame-delivery queue so `startRunning` can't stall frames or race stop.
	private let sessionQueue = DispatchQueue(label: "com.messageandliveness.camera.session")
	private let sampleQueue = DispatchQueue(label: "com.messageandliveness.camera.samples")
	private let detector: LivenessDetector
	private var forwarder: CameraFrameForwarder?
	private let ciContext = CIContext()

	// Front camera in portrait: tell ML Kit how the buffer is oriented rather
	// than transforming the capture connection (which would double-rotate).
	private let mlOrientation: UIImage.Orientation = .leftMirrored

	nonisolated init(detector: LivenessDetector = LivenessDetectorFactory.make()) {
		self.detector = detector
	}

	/// A still image of the most recent camera frame, oriented upright and
	/// mirrored like the preview. Used to capture the liveness selfie.
	func snapshot() -> CGImage? {
		guard let pixelBuffer = forwarder?.latestPixelBuffer() else { return nil }
		let image = CIImage(cvPixelBuffer: pixelBuffer).oriented(.leftMirrored)
		return ciContext.createCGImage(image, from: image.extent)
	}

	func start() async {
		guard setupState == .idle || setupState == .failed || setupState == .denied else { return }
		setupState = .configuring

		guard await Self.requestCameraAccess() else {
			setupState = .denied
			return
		}

		// All session control runs on `sessionQueue` (serial); frames are delivered
		// on the separate `sampleQueue`. This prevents `stopRunning` racing a
		// begin/commit and keeps `startRunning` from stalling frame delivery.
		let session = session
		let videoOutput = videoOutput
		let sampleQueue = sampleQueue
		let forwarder = CameraFrameForwarder(
			detector: detector,
			orientation: mlOrientation
		) { [weak self] signals in
			self?.onSignals?(signals)
		}
		self.forwarder = forwarder

		let configured: Bool = await withCheckedContinuation { continuation in
			sessionQueue.async {
				session.beginConfiguration()
				session.sessionPreset = .high

				guard
					let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
					let input = try? AVCaptureDeviceInput(device: device),
					session.canAddInput(input)
				else {
					session.commitConfiguration()
					continuation.resume(returning: false)
					return
				}
				session.addInput(input)

				videoOutput.videoSettings = [
					kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
				]
				videoOutput.alwaysDiscardsLateVideoFrames = true
				videoOutput.setSampleBufferDelegate(forwarder, queue: sampleQueue)

				guard session.canAddOutput(videoOutput) else {
					session.commitConfiguration()
					continuation.resume(returning: false)
					return
				}
				session.addOutput(videoOutput)
				session.commitConfiguration()

				session.startRunning()
				continuation.resume(returning: true)
			}
		}

		setupState = configured ? .ready : .failed
		#if DEBUG
		print("📷 liveness camera — configured:\(configured) running:\(session.isRunning)")
		#endif
	}

	func stop() {
		let session = session
		sessionQueue.async {
			if session.isRunning { session.stopRunning() }
		}
	}

	private static func requestCameraAccess() async -> Bool {
		switch AVCaptureDevice.authorizationStatus(for: .video) {
		case .authorized:
			return true
		case .notDetermined:
			return await AVCaptureDevice.requestAccess(for: .video)
		default:
			return false
		}
	}
}

/// Nonisolated capture delegate. Runs on the camera sample queue, forwards each
/// frame to the detector, and marshals results back to the main queue.
private nonisolated final class CameraFrameForwarder: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {

	private let detector: LivenessDetector
	private let orientation: UIImage.Orientation
	private let onSignals: (FaceSignals) -> Void

	private let bufferLock = NSLock()
	private var latestBuffer: CVPixelBuffer?

	init(
		detector: LivenessDetector,
		orientation: UIImage.Orientation,
		onSignals: @escaping (FaceSignals) -> Void
	) {
		self.detector = detector
		self.orientation = orientation
		self.onSignals = onSignals
	}

	/// Thread-safe accessor for the most recent frame (used for the selfie snapshot).
	func latestPixelBuffer() -> CVPixelBuffer? {
		bufferLock.lock()
		defer { bufferLock.unlock() }
		return latestBuffer
	}

	func captureOutput(
		_ output: AVCaptureOutput,
		didOutput sampleBuffer: CMSampleBuffer,
		from connection: AVCaptureConnection
	) {
		if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
			bufferLock.lock()
			latestBuffer = pixelBuffer
			bufferLock.unlock()
		}

		let onSignals = onSignals
		detector.detect(in: sampleBuffer, orientation: orientation) { signals in
			guard let signals else { return }
			DispatchQueue.main.async {
				onSignals(signals)
			}
		}
	}
}
