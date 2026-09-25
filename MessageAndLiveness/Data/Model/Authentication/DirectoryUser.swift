//
//  DirectoryUser.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//

import Foundation

/// One entry of `GET /api/users` — the people directory used to start a new
/// chat. Deliberately lighter than `AuthUser` (that endpoint returns only
/// `id`, `name`, `avatar_url`).
nonisolated struct DirectoryUser: Decodable, Identifiable, Equatable {
	let id: Int
	let name: String
	let avatarURL: String?

	enum CodingKeys: String, CodingKey {
		case id, name
		case avatarURL = "avatar_url"
	}

	var initials: String {
		let letters = name.split(separator: " ").prefix(2).compactMap { $0.first }
		return String(letters).uppercased()
	}
}
