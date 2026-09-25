//
//  BirchLabsAuthenticationRepository.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 25/09/26.
//
//  BirchLabs mobile API implementation of `AuthenticationRepository`
//  (replaces the previous Firebase Auth backend). Stores the Sanctum
//  access/refresh tokens and the cached user via `AuthTokenStore`.
//

import Foundation

nonisolated final class BirchLabsAuthenticationRepository: AuthenticationRepository {

	private let tokenStore: AuthTokenStore
	private let client: APIClient

	init() {
		let store = AuthTokenStore()
		self.tokenStore = store
		self.client = APIClient(tokenStore: store)
	}

	var currentUser: AuthUser? {
		tokenStore.accessToken != nil ? tokenStore.cachedUser : nil
	}

	@discardableResult
	func signIn(email: String, password: String) async throws -> AuthUser {
		do {
			let session = try await client.send(.login(email: email, password: password), decoding: AuthSession.self)
			tokenStore.save(access: session.token, refresh: session.refreshToken, user: session.user)
			return session.user
		} catch {
			throw Self.mapped(error)
		}
	}

	@discardableResult
	func register(fullName: String, email: String, password: String, passwordConfirmation: String) async throws -> AuthUser {
		do {
			let session = try await client.send(
				.register(name: fullName, email: email, password: password, passwordConfirmation: passwordConfirmation),
				decoding: AuthSession.self
			)
			tokenStore.save(access: session.token, refresh: session.refreshToken, user: session.user)
			return session.user
		} catch {
			throw Self.mapped(error)
		}
	}

	func signOut() async {
		try? await client.sendVoid(.logout)   // best effort; local tokens cleared regardless
		tokenStore.clear()
	}

	func streamCredentials() async throws -> StreamCredentials {
		try await client.send(.streamToken, decoding: StreamCredentials.self)
	}

	func channels() async throws -> [ChannelSummary] {
		try await client.send(.channels, decoding: [ChannelSummary].self)
	}

	func users() async throws -> [DirectoryUser] {
		try await client.send(.users, decoding: [DirectoryUser].self)
	}

	@discardableResult
	func createChannel(members: [Int], name: String?) async throws -> ChannelSummary {
		do {
			return try await client.send(.createChannel(members: members, name: name), decoding: ChannelSummary.self)
		} catch {
			throw Self.mapped(error)
		}
	}
}

private extension BirchLabsAuthenticationRepository {
	static func mapped(_ error: Error) -> AuthError {
		guard let apiError = error as? APIError else {
			return .unknown(error.localizedDescription)
		}
		switch apiError.httpStatus {
		case 401, 403:
			return .invalidCredential
		case 422:
			return .validation(apiError.errorDescription ?? "Please check your details and try again.")
		case .some(let code) where code >= 500:
			return .server
		default:
			return .unknown(apiError.errorDescription ?? "Something went wrong.")
		}
	}
}
