//
//  APIClient.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 25/09/26.
//
//  Minimal async URLSession client for the BirchLabs mobile API
//  (https://play.birchlabs.tech). Every response is wrapped in a
//  `{ success, status_code, message, data }` envelope; this unwraps `data`.
//

import Foundation

// MARK: - Envelope + errors

private nonisolated struct APIEnvelope<T: Decodable>: Decodable {
	let success: Bool
	let message: String?
	let data: T
}

private nonisolated struct APIErrorEnvelope: Decodable {
	let message: String?
	let errors: [String: [String]]?

	var bestMessage: String? {
		if let first = errors?.values.first?.first { return first }
		return message
	}
}

nonisolated enum APIError: LocalizedError {
	case invalidResponse
	case http(status: Int, message: String?)
	case decoding
	case network(String)

	var errorDescription: String? {
		switch self {
		case .invalidResponse:
			return "Unexpected server response. Please try again."
		case .http(_, let message):
			return message ?? "Request failed. Please try again."
		case .decoding:
			return "Couldn't read the server response."
		case .network(let message):
			return message
		}
	}

	var httpStatus: Int? {
		if case .http(let status, _) = self { return status }
		return nil
	}
}

// MARK: - Endpoint

nonisolated struct APIEndpoint {
	enum Auth { case none, access, refresh }

	let path: String
	let method: String
	let body: [String: Any]?
	let auth: Auth

	static func login(email: String, password: String) -> APIEndpoint {
		.init(path: "/api/login", method: "POST",
			  body: ["email": email, "password": password], auth: .none)
	}

	static func register(name: String, email: String, password: String, passwordConfirmation: String) -> APIEndpoint {
		.init(path: "/api/register", method: "POST",
			  body: ["name": name, "email": email, "password": password, "password_confirmation": passwordConfirmation],
			  auth: .none)
	}

	static let currentUser = APIEndpoint(path: "/api/user", method: "GET", body: nil, auth: .access)
	static let logout = APIEndpoint(path: "/api/logout", method: "POST", body: nil, auth: .access)
	static let streamToken = APIEndpoint(path: "/api/stream/token", method: "GET", body: nil, auth: .access)
	static let channels = APIEndpoint(path: "/api/channels", method: "GET", body: nil, auth: .access)
	static let users = APIEndpoint(path: "/api/users", method: "GET", body: nil, auth: .access)

	/// Creates (or fetches, via Stream's get-or-create) a messaging channel.
	/// The caller is always auto-included as a member; `name` is optional.
	static func createChannel(members: [Int], name: String?) -> APIEndpoint {
		var body: [String: Any] = ["members": members]
		if let name, !name.isEmpty { body["name"] = name }
		return .init(path: "/api/channels", method: "POST", body: body, auth: .access)
	}
}

// MARK: - Client

nonisolated final class APIClient: @unchecked Sendable {

	static let baseURL = URL(string: "https://play.birchlabs.tech")!

	private let session: URLSession
	private let tokenStore: AuthTokenStore

	init(tokenStore: AuthTokenStore, session: URLSession = .shared) {
		self.tokenStore = tokenStore
		self.session = session
	}

	/// Sends the request and returns the decoded `data` payload.
	func send<T: Decodable>(_ endpoint: APIEndpoint, decoding: T.Type) async throws -> T {
		let data = try await perform(endpoint)
		do {
			return try JSONDecoder().decode(APIEnvelope<T>.self, from: data).data
		} catch {
			throw APIError.decoding
		}
	}

	/// Sends the request and ignores the response body (e.g. logout).
	func sendVoid(_ endpoint: APIEndpoint) async throws {
		_ = try await perform(endpoint)
	}

	private func perform(_ endpoint: APIEndpoint) async throws -> Data {
		var request = URLRequest(url: Self.baseURL.appendingPathComponent(endpoint.path))
		request.httpMethod = endpoint.method
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("application/json", forHTTPHeaderField: "Accept")

		switch endpoint.auth {
		case .none:
			break
		case .access:
			if let token = tokenStore.accessToken {
				request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
			}
		case .refresh:
			if let token = tokenStore.refreshToken {
				request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
			}
		}

		if let body = endpoint.body {
			request.httpBody = try? JSONSerialization.data(withJSONObject: body)
		}

		let data: Data
		let response: URLResponse
		do {
			(data, response) = try await session.data(for: request)
		} catch {
			throw APIError.network(error.localizedDescription)
		}

		guard let http = response as? HTTPURLResponse else {
			throw APIError.invalidResponse
		}
		guard (200..<300).contains(http.statusCode) else {
			let message = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data).bestMessage
			throw APIError.http(status: http.statusCode, message: message ?? nil)
		}
		return data
	}
}
