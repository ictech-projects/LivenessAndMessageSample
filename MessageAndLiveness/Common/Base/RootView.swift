//
//  RootView.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import SwiftUI

/// Switches between login, the identity/liveness gate, and Home based on the
/// session phase.
struct RootView: View {

	@EnvironmentObject private var session: SessionStore

	var body: some View {
		Group {
			switch session.phase {
			case .signedOut:
				NavigationStack {
					LoginView()
				}
				.transition(.opacity)

			case .needsVerification:
				IdentityVerificationView(
					onVerified: { session.handleVerified() },
					onFailed: { session.failVerification() }
				)
				.transition(.opacity)

			case .verified:
				HomeView()
					.transition(.opacity)
			}
		}
		.animation(.easeInOut(duration: 0.3), value: session.phase)
	}
}

#Preview {
	RootView()
		.environmentObject(SessionStore())
}
