//
//  AuthenticationRepository.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import Foundation

/// Abstraction over the authentication provider (the BirchLabs mobile API).
///
/// Nonisolated so it can be a default argument and called from any actor; the
/// async methods hop as needed.
protocol AuthenticationRepository: Sendable {
	/// The cached signed-in user (from a persisted token), or `nil`.
	var currentUser: AuthUser? { get }

	@discardableResult
	func signIn(email: String, password: String) async throws -> AuthUser

	@discardableResult
	func register(fullName: String, email: String, password: String, passwordConfirmation: String) async throws -> AuthUser

	func signOut() async

	/// Stream Chat/Video credentials for the signed-in user.
	func streamCredentials() async throws -> StreamCredentials

	/// The signed-in user's chat channels (inbox list).
	func channels() async throws -> [ChannelSummary]

	/// The people directory used to start a new chat.
	func users() async throws -> [DirectoryUser]

	/// Creates (or fetches) a channel with the given member ids + optional name.
	@discardableResult
	func createChannel(members: [Int], name: String?) async throws -> ChannelSummary
}
