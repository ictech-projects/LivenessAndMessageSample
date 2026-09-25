//
//  AuthTokenStore.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 25/09/26.
//

import Foundation

/// Persists the BirchLabs access/refresh tokens (Keychain) and the cached user
/// (UserDefaults), so the session survives relaunches.
nonisolated final class AuthTokenStore: @unchecked Sendable {

	private let keychain = KeychainHelper.shared
	private let defaults = UserDefaults.standard
	private let userKey = "messageandliveness.auth.cached_user"

	var accessToken: String? { keychain.getString(for: KeychainKey.accessToken.key) }
	var refreshToken: String? { keychain.getString(for: KeychainKey.refreshToken.key) }

	var cachedUser: AuthUser? {
		guard let data = defaults.data(forKey: userKey) else { return nil }
		return try? JSONDecoder().decode(AuthUser.self, from: data)
	}

	func save(access: String, refresh: String, user: AuthUser) {
		keychain.save(access, for: KeychainKey.accessToken.key)
		keychain.save(refresh, for: KeychainKey.refreshToken.key)
		if let data = try? JSONEncoder().encode(user) {
			defaults.set(data, forKey: userKey)
		}
	}

	func clear() {
		keychain.delete(for: KeychainKey.accessToken.key)
		keychain.delete(for: KeychainKey.refreshToken.key)
		defaults.removeObject(forKey: userKey)
	}
}
