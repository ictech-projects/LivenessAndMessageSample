//
//  AuthScaffold.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import SwiftUI
import UIKit

/// Shared chrome for the auth screens: a branded gradient header with the app
/// mark + title, and a scrollable content area below that dismisses the
/// keyboard interactively.
struct AuthScaffold<Content: View>: View {

	let title: String
	let subtitle: String
	var showsBack: Bool = false
	var onBack: (() -> Void)? = nil
	@ViewBuilder let content: () -> Content

	var body: some View {
		ScrollView(showsIndicators: false) {
			VStack(spacing: 0) {
				header
				content()
					.padding(.horizontal, 24)
					.padding(.top, 28)
					.padding(.bottom, 40)
			}
			// Keep the form a readable width and centered on iPad / large widths.
			.frame(maxWidth: 560)
			.frame(maxWidth: .infinity)
		}
		.background(Color(.systemBackground))
		.scrollDismissesKeyboard(.interactively)
		.ignoresSafeArea(edges: .top)
	}

	private var header: some View {
		ZStack(alignment: .topLeading) {
			LinearGradient(
				colors: [.brandSecondary, .brandPrimary],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)

			if showsBack {
				Button {
					onBack?()
				} label: {
					Image(systemName: "chevron.left")
						.font(.system(size: 16, weight: .bold))
						.foregroundStyle(.white)
						.frame(width: 40, height: 40)
						.background(Circle().fill(.white.opacity(0.18)))
				}
				.accessibilityLabel("Back")
				.padding(.leading, 20)
				.padding(.top, 60)
			}

			VStack(alignment: .leading, spacing: 16) {
				appMark

				VStack(alignment: .leading, spacing: 6) {
					Text(title)
						.font(.baseStyle(size: 28, weight: .bold))
						.foregroundStyle(.white)

					Text(subtitle)
						.font(.baseStyle(size: 15, weight: .regular))
						.foregroundStyle(.white.opacity(0.85))
				}
			}
			.padding(.horizontal, 24)
			.padding(.top, showsBack ? 112 : 96)
			.padding(.bottom, 36)
			.frame(maxWidth: .infinity, alignment: .leading)
		}
		.clipShape(BottomRoundedShape(radius: 32))
		.accessibilityElement(children: .combine)
	}

	private var appMark: some View {
		Image(.mainAppLogo)
			.resizable()
			.scaledToFit()
			.frame(width: 40, height: 40)
			.padding(14)
			.background(Circle().fill(.white))
			.shadow(color: .black.opacity(0.12), radius: 8, y: 4)
	}
}

/// A rectangle with only its bottom corners rounded.
private struct BottomRoundedShape: Shape {
	let radius: CGFloat

	func path(in rect: CGRect) -> Path {
		Path(
			UIBezierPath(
				roundedRect: rect,
				byRoundingCorners: [.bottomLeft, .bottomRight],
				cornerRadii: CGSize(width: radius, height: radius)
			).cgPath
		)
	}
}

#Preview {
	AuthScaffold(title: "Welcome back", subtitle: "Sign in to continue") {
		VStack {
			Text("Content")
		}
	}
}
