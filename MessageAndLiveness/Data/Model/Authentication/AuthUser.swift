//
//  AuthUser.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import Foundation

/// Authenticated user as returned by the BirchLabs API (`data.user`).
nonisolated struct AuthUser: Hashable, Identifiable, Codable {
	let id: Int
	let name: String
	let email: String
	let role: String?
	let avatarURL: String?
	let onBoardRequired: Bool?

	enum CodingKeys: String, CodingKey {
		case id, name, email, role
		case avatarURL = "avatar_url"
		case onBoardRequired = "on_board_required"
	}

	var displayName: String { name }
}
