//
//  SessionStore.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import Combine
import Foundation

/// App-wide auth + verification state, injected through the environment so the
/// root view can switch between login, the identity/liveness gate, and Home.
///
/// Auth is backed by the BirchLabs API. After a passing identity gate the app
/// connects the Stream Chat client using `GET /api/stream/token`.
@MainActor
final class SessionStore: ObservableObject {

	enum Phase: Equatable {
		case signedOut
		case needsVerification
		case verified
	}

	@Published private(set) var phase: Phase
	@Published private(set) var currentUser: AuthUser?

	let authRepository: any AuthenticationRepository
	private let livenessStore: LivenessVerificationStore

	init(
		authRepository: any AuthenticationRepository = BirchLabsAuthenticationRepository(),
		livenessStore: LivenessVerificationStore = LivenessVerificationStore()
	) {
		self.authRepository = authRepository
		self.livenessStore = livenessStore

		// Restore on launch: a persisted, already-liveness-verified user goes
		// straight to chat; otherwise the identity gate. Survives termination.
		let existing = authRepository.currentUser
		self.currentUser = existing
		if let existing, livenessStore.isVerified(userID: existing.id) {
			self.phase = .verified
		} else {
			self.phase = existing == nil ? .signedOut : .needsVerification
		}

		if phase == .verified {
			Task { await connectStream() }
		}
	}

	/// After a successful login/registration — skips straight to chat if this
	/// user has already passed liveness, otherwise routes into the identity gate.
	func handleAuthenticated(_ user: AuthUser) {
		currentUser = user
		if livenessStore.isVerified(userID: user.id) {
			handleVerified()
		} else {
			phase = .needsVerification
		}
	}

	/// Identity + liveness passed — persist it, connect Stream and show Home.
	func handleVerified() {
		if let id = currentUser?.id {
			livenessStore.setVerified(userID: id)
		}
		phase = .verified
		Task { await connectStream() }
	}

	/// Verification failed / user backed out — return to the root.
	func failVerification() {
		signOut()
	}

	func signOut() {
		// Clear this user's persisted liveness flag so the next login must pass
		// the identity/liveness gate again.
		if let id = currentUser?.id {
			livenessStore.clear(userID: id)
		}
		StreamChatService.shared.disconnect()
		let repository = authRepository
		Task { await repository.signOut() }
		currentUser = nil
		phase = .signedOut
	}

	private func connectStream() async {
		do {
			let credentials = try await authRepository.streamCredentials()
			await StreamChatService.shared.connect(credentials)
		} catch {
			#if DEBUG
			print("⚠️ Stream connect failed: \(error)")
			#endif
		}
	}
}
