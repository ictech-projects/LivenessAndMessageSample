//
//  AuthError.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import Foundation

/// Provider-agnostic authentication error. BirchLabs API errors are mapped into
/// these cases so the UI can show friendly copy.
nonisolated enum AuthError: LocalizedError, Equatable {
	case invalidCredential
	/// A 422 validation error, carrying the server's message.
	case validation(String)
	case network
	case server
	case unknown(String)

	var errorDescription: String? {
		switch self {
		case .invalidCredential:
			return "The email or password you entered is incorrect."
		case .validation(let message):
			return message
		case .network:
			return "We couldn't reach the server. Check your connection and try again."
		case .server:
			return "The server had a problem. Please try again shortly."
		case .unknown(let message):
			return message
		}
	}
}
