//
//  LaunchScreenView.swift
//  MessageAndLiveness
//
//  Created by Arifin Firdaus on 27/01/26.
//

import SwiftUI


/// A programmatic launch screen view.
///
/// Unlike the default Launch Screen configuration using Info.plist
/// and storyboard (recommended by Apple for simple static launch UI),
/// this view allows adding runtime logic before routing.
///
/// Apple’s Launch Screen API (plist + storyboard) is fast and simple,
/// but does not support:
/// - Async operations
/// - Conditional routing
/// - State-based transitions
///
/// This programmatic approach is commonly used to:
/// - Fetch force update status and route to a Force Update screen
/// - Validate authentication token and route to Home or Login
/// - Display a short loading state before entering the main flow
///
/// Note:
/// This is NOT a replacement for the required static LaunchScreen file.
/// It is shown immediately after the system launch screen.
struct LaunchScreenView: View {
	
	@StateObject private var viewModel = LaunchScreenViewModel()
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				
				// TODO: Background placeholder image (replace with your asset)
				Image(.launchScreen)
					.resizable()
					.ignoresSafeArea()
					
				
				VStack {
					Spacer()
					
					Text("Programmatic Launch Screen")
						.foregroundStyle(.neutral10)
						.font(.headline)
						.padding(.bottom, 8)
					
					Text("Preparing application...")
						.foregroundStyle(.neutral30)
						.font(.subheadline)
					
					Spacer()
					
					// ProgressView positioned at 1/4 bottom height
					ProgressView()
						.progressViewStyle(.circular)
						.scaleEffect(1.2)
						.tint(.neutral60)
						.padding(.bottom, geometry.size.height / 4)
				}
				.padding()
			}
		}
	}
}

#Preview {
	LaunchScreenView()
}
