//
//  LoadingOverlay.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import SwiftUI

/// A lightweight blocking overlay for simple `Bool`-driven loading states,
/// where the full `RequestState`-based `LoadingView` would be overkill.
struct LoadingOverlay: View {
	let message: String

	var body: some View {
		ZStack {
			Color.black.opacity(0.35)
				.ignoresSafeArea()

			VStack(spacing: 16) {
				ProgressView()
					.controlSize(.large)
					.tint(.white)

				Text(message)
					.font(.baseStyle(size: 14, weight: .medium))
					.foregroundStyle(.white)
			}
			.padding(28)
			.background(
				RoundedRectangle(cornerRadius: 16)
					.fill(.black.opacity(0.55))
					.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
			)
		}
	}
}

#Preview {
	ZStack {
		Color.neutral10
		LoadingOverlay(message: "Signing you in…")
	}
}
