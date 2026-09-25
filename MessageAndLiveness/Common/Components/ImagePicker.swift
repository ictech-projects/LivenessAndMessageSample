//
//  ImagePicker.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//

import SwiftUI
import UIKit

/// Thin SwiftUI wrapper over `UIImagePickerController` for capturing a document
/// photo from the camera or picking one from the library.
struct ImagePicker: UIViewControllerRepresentable {

	let sourceType: UIImagePickerController.SourceType
	let onImage: (UIImage) -> Void

	@Environment(\.dismiss) private var dismiss

	static var isCameraAvailable: Bool {
		UIImagePickerController.isSourceTypeAvailable(.camera)
	}

	func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.sourceType = sourceType
		picker.delegate = context.coordinator
		if sourceType == .camera {
			picker.cameraDevice = .rear
		}
		return picker
	}

	func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
		private let parent: ImagePicker

		init(_ parent: ImagePicker) {
			self.parent = parent
		}

		func imagePickerController(
			_ picker: UIImagePickerController,
			didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
		) {
			if let image = info[.originalImage] as? UIImage {
				parent.onImage(image)
			}
			parent.dismiss()
		}

		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			parent.dismiss()
		}
	}
}
