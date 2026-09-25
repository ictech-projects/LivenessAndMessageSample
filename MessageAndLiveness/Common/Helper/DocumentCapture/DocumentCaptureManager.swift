//
//  DocumentCaptureManager.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//
//  Live back-camera capture for the ID document, using Google ML Kit Object
//  Detection (streaming) to drive a "hold the document in frame" guide before
//  capture. When a prominent object fills and centers within the frame, the
//  guide turns green and the frame auto-captures.
//

@preconcurrency import AVFoundation
import Combine
import CoreImage
import CoreMedia
import QuartzCore
import UIKit

/// Instantaneous alignment of the document within the camera frame.
nonisolated enum DocumentAlignment: Equatable {
	case searching
	case moveCloser
	case center
	case aligned

	var message: String {
		switch self {
		case .searching: return "Point the camera at your ID"
		case .moveCloser: return "Move closer to fill the frame"
		case .center: return "Center the document in the box"
		case .aligned: return "Hold steady…"
		}
	}

	var isAligned: Bool { self == .aligned }
}

@MainActor
final class DocumentCaptureManager: ObservableObject {

	enum SetupState: Equatable {
		case idle, configuring, ready, denied, failed
	}

	@Published private(set) var setupState: SetupState = .idle
	@Published private(set) var alignment: DocumentAlignment = .searching
	/// True once the document has been well-aligned for a stable moment.
	@Published private(set) var readyToCapture = false

	let session = AVCaptureSession()

	private let videoOutput = AVCaptureVideoDataOutput()
	/// Serialises session control, separate from the frame-delivery queue.
	private let sessionQueue = DispatchQueue(label: "com.messageandliveness.document.session")
	private let sampleQueue = DispatchQueue(label: "com.messageandliveness.document.samples")
	private var forwarder: DocumentFrameForwarder?
	private let ciContext = CIContext()

	// Back camera in portrait.
	private let mlOrientation: UIImage.Orientation = .right

	nonisolated init() {}

	/// A still image of the most recent frame, oriented upright.
	func snapshot() -> CGImage? {
		guard let pixelBuffer = forwarder?.latestPixelBuffer() else { return nil }
		let image = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
		return ciContext.createCGImage(image, from: image.extent)
	}

	func start() async {
		guard setupState == .idle || setupState == .failed || setupState == .denied else { return }
		setupState = .configuring

		guard await Self.requestCameraAccess() else {
			setupState = .denied
			return
		}

		// Session control on `sessionQueue`; frames on `sampleQueue`.
		let session = session
		let videoOutput = videoOutput
		let sampleQueue = sampleQueue
		let forwarder = DocumentFrameForwarder(orientation: mlOrientation) { [weak self] alignment, ready in
			self?.alignment = alignment
			self?.readyToCapture = ready
		}
		self.forwarder = forwarder

		let configured: Bool = await withCheckedContinuation { continuation in
			sessionQueue.async {
				session.beginConfiguration()
				session.sessionPreset = .high

				guard
					let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
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
		print("📄 document camera — configured:\(configured) running:\(session.isRunning)")
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
		case .authorized: return true
		case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
		default: return false
		}
	}
}

/// Nonisolated capture delegate: retains the latest frame and runs ML Kit
/// Object Detection (throttled) to compute document alignment.
private nonisolated final class DocumentFrameForwarder: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {

	private let orientation: UIImage.Orientation
	private let onAlignment: (DocumentAlignment, Bool) -> Void

	private let bufferLock = NSLock()
	private var latestBuffer: CVPixelBuffer?

	private let throttleLock = NSLock()
	private var lastAt: CFTimeInterval = 0
	private let interval: CFTimeInterval = 0.2

	private var alignedStreak = 0
	private let stableFrames = 4

	init(
		orientation: UIImage.Orientation,
		onAlignment: @escaping (DocumentAlignment, Bool) -> Void
	) {
		self.orientation = orientation
		self.onAlignment = onAlignment
	}

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
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
		bufferLock.lock()
		latestBuffer = pixelBuffer
		bufferLock.unlock()

		let now = CACurrentMediaTime()
		throttleLock.lock()
		let due = now - lastAt >= interval
		if due { lastAt = now }
		throttleLock.unlock()
		guard due else { return }

		let width = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
		let height = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

		evaluate(sampleBuffer, imageWidth: width, imageHeight: height)
	}

	#if canImport(MLKitObjectDetection) && canImport(MLKitVision)
	private let detector = MLKitObjectDetectorBox()

	private func evaluate(_ sampleBuffer: CMSampleBuffer, imageWidth: CGFloat, imageHeight: CGFloat) {
		detector.process(sampleBuffer, orientation: orientation) { [weak self] boxes in
			guard let self else { return }
			let alignment = self.alignment(for: boxes, imageWidth: imageWidth, imageHeight: imageHeight)
			let ready = alignment.isAligned && self.alignedStreak >= self.stableFrames
			DispatchQueue.main.async { self.onAlignment(alignment, ready) }
		}
	}
	#else
	private func evaluate(_ sampleBuffer: CMSampleBuffer, imageWidth: CGFloat, imageHeight: CGFloat) {
		DispatchQueue.main.async { self.onAlignment(.searching, false) }
	}
	#endif

	/// Heuristic: pick the largest detected object and check that it fills and
	/// centers the frame. Area ratio is orientation-independent; centering uses
	/// the raw buffer axes (close enough for a live guide).
	private func alignment(for boxes: [CGRect], imageWidth: CGFloat, imageHeight: CGFloat) -> DocumentAlignment {
		guard imageWidth > 0, imageHeight > 0,
			  let box = boxes.max(by: { $0.width * $0.height < $1.width * $1.height }) else {
			alignedStreak = 0
			return .searching
		}

		let areaRatio = (box.width * box.height) / (imageWidth * imageHeight)
		let offsetX = abs(box.midX / imageWidth - 0.5)
		let offsetY = abs(box.midY / imageHeight - 0.5)

		if areaRatio < 0.30 {
			alignedStreak = 0
			return .moveCloser
		}
		if offsetX > 0.22 || offsetY > 0.22 {
			alignedStreak = 0
			return .center
		}
		alignedStreak += 1
		return .aligned
	}
}
