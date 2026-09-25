//
//  CameraPreviewView.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import AVFoundation
import SwiftUI
import UIKit

/// Thin SwiftUI wrapper around `AVCaptureVideoPreviewLayer`.
struct CameraPreviewView: UIViewRepresentable {

	let session: AVCaptureSession
	/// Mirror the preview (front-camera selfie). Off for the back camera.
	var mirrored: Bool = true

	func makeUIView(context: Context) -> PreviewView {
		let view = PreviewView()
		view.backgroundColor = .black
		view.videoPreviewLayer.session = session
		view.videoPreviewLayer.videoGravity = .resizeAspectFill

		if let connection = view.videoPreviewLayer.connection {
			connection.automaticallyAdjustsVideoMirroring = false
			connection.isVideoMirrored = mirrored
			if connection.isVideoRotationAngleSupported(90) {
				connection.videoRotationAngle = 90 // portrait
			}
		}
		return view
	}

	func updateUIView(_ uiView: PreviewView, context: Context) {}

	final class PreviewView: UIView {
		override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

		var videoPreviewLayer: AVCaptureVideoPreviewLayer {
			// swiftlint:disable:next force_cast
			layer as! AVCaptureVideoPreviewLayer
		}
	}
}
