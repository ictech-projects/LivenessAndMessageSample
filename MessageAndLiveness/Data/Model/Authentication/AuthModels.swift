//
//  AuthModels.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 25/09/26.
//

import Foundation

/// `data` payload of `POST /api/login` and `/api/register`.
nonisolated struct AuthSession: Decodable {
	let user: AuthUser
	let token: String
	let refreshToken: String
	let refreshExpiresAt: String?

	enum CodingKeys: String, CodingKey {
		case user, token
		case refreshToken = "refresh_token"
		case refreshExpiresAt = "refresh_expires_at"
	}
}

/// `data` payload of `GET /api/stream/token` — feeds the Stream SDK.
nonisolated struct StreamCredentials: Decodable, Equatable {
	let apiKey: String
	let userId: String
	let userName: String
	let token: String

	enum CodingKeys: String, CodingKey {
		case apiKey = "api_key"
		case userId = "user_id"
		case userName = "user_name"
		case token
	}
}

/// One entry of `GET /api/channels` — used for the chat inbox list.
nonisolated struct ChannelSummary: Decodable, Identifiable, Hashable {
	let id: Int
	let streamChannelId: String
	let type: String
	let name: String?
	let createdBy: AuthUser?
	let members: [AuthUser]

	enum CodingKeys: String, CodingKey {
		case id, type, name, members
		case streamChannelId = "stream_channel_id"
		case createdBy = "created_by"
	}

	/// Title for the inbox row: explicit name, else the other members' names.
	func title(currentUserID: Int?) -> String {
		if let name, !name.isEmpty { return name }
		let others = members.filter { $0.id != currentUserID }
		let names = others.map(\.name)
		return names.isEmpty ? "Chat" : names.joined(separator: ", ")
	}
}
