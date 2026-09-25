//
//  CountryFlagView.swift
// MessageAndLiveness
//
//  Created by Arifin Firdaus on 29/12/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct CountryFlagView: View {
	let urlString: String?
	let flagImage: UIImage?
	
	private let size: CGFloat = 24
	
	var body: some View {
		Group {
			if let urlString,
			   let url = URL(string: urlString) {
				
				WebImage(
					url: url,
					transaction: Transaction(animation: .easeInOut(duration: 0.5))
				) { phase in
					switch phase {
					case .success(let image):
						image
							.resizable()
							.scaledToFill()
						
					case .failure:
						fallbackImage
						
					default: // loading / empty
						placeholder
					}
				}
				
			} else if let flagImage {
				
				Image(uiImage: flagImage)
					.resizable()
					.scaledToFill()
				
			} else {
				
				placeholder
			}
		}
		.frame(width: size, height: size)
		.clipShape(Circle())
	}
}

private extension CountryFlagView {
	var placeholder: some View {
		Color.secondary.opacity(0.3)
	}
	
	var fallbackImage: some View {
		Image(systemName: "flag.fill")
			.resizable()
			.scaledToFit()
			.padding(4)
			.foregroundStyle(.secondary)
	}
}

// MARK: - Preview

#Preview("CountryFlagView - All Scenarios") {
	VStack(spacing: 20) {
		
		// 1. Valid URL
		CountryFlagView(
			urlString: "https://flagcdn.com/w40/id.png",
			flagImage: nil
		)
		
		// 2. Invalid URL (will trigger fallback)
		CountryFlagView(
			urlString: "https://invalid-url.com/flag.png",
			flagImage: nil
		)
		
		// 3. Local UIImage only
		CountryFlagView(
			urlString: nil,
			flagImage: UIImage(systemName: "globe")
		)
		
		// 4. No URL and no UIImage (placeholder)
		CountryFlagView(
			urlString: nil,
			flagImage: nil
		)
	}
	.padding()
}
