//
//  LivenessVerificationStore.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 25/09/26.
//
//  Persists which users have already passed the liveness/identity gate, so a
//  verified user goes straight to chat on the next login and survives app
//  termination. Backed by UserDefaults (local storage) for now — keyed per
//  user id so one account's verification never applies to another.
//

import Foundation

nonisolated final class LivenessVerificationStore: @unchecked Sendable {

	private let defaults: UserDefaults
	private let key = "messageandliveness.liveness.verified_user_ids"

	init(defaults: UserDefaults = .standard) {
		self.defaults = defaults
	}

	/// Whether this user has already passed the liveness gate.
	func isVerified(userID: Int) -> Bool {
		verifiedIDs().contains(userID)
	}

	/// Marks the user as liveness-verified (persisted across launches).
	func setVerified(userID: Int) {
		var ids = verifiedIDs()
		guard !ids.contains(userID) else { return }
		ids.insert(userID)
		save(ids)
	}

	/// Clears a single user's verification (e.g. to force a re-check).
	func clear(userID: Int) {
		var ids = verifiedIDs()
		guard ids.remove(userID) != nil else { return }
		save(ids)
	}

	private func verifiedIDs() -> Set<Int> {
		let raw = defaults.array(forKey: key) as? [Int] ?? []
		return Set(raw)
	}

	private func save(_ ids: Set<Int>) {
		defaults.set(Array(ids), forKey: key)
	}
}
