//
//  NewChatViewModel.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//
//  Backs the "start a new chat" screen: loads the people directory
//  (`GET /api/users`), tracks a selection, and creates the channel
//  (`POST /api/channels`).
//

import Combine
import Foundation

@MainActor
final class NewChatViewModel: ObservableObject {

	@Published private(set) var users: [DirectoryUser] = []
	@Published private(set) var isLoading = false
	@Published private(set) var isCreating = false
	@Published var errorMessage: String?
	@Published var searchText = ""
	@Published var selectedIDs: Set<Int> = []

	/// Set when a channel has been created, so the view can navigate into it.
	@Published var createdChannel: ChannelSummary?

	private let repository: any AuthenticationRepository

	init(repository: any AuthenticationRepository = BirchLabsAuthenticationRepository()) {
		self.repository = repository
	}

	var filteredUsers: [DirectoryUser] {
		let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		guard !query.isEmpty else { return users }
		return users.filter { $0.name.lowercased().contains(query) }
	}

	var canCreate: Bool { !selectedIDs.isEmpty && !isCreating }

	func toggle(_ user: DirectoryUser) {
		if selectedIDs.contains(user.id) {
			selectedIDs.remove(user.id)
		} else {
			selectedIDs.insert(user.id)
		}
	}

	func load() async {
		isLoading = true
		defer { isLoading = false }
		do {
			users = try await repository.users()
		} catch {
			errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
		}
	}

	func createChannel() async {
		guard !selectedIDs.isEmpty else { return }
		isCreating = true
		defer { isCreating = false }

		// Name a group chat from the picked members; leave DMs unnamed so the
		// inbox derives the title from the other participant.
		let picked = users.filter { selectedIDs.contains($0.id) }
		let name = picked.count > 1 ? picked.map(\.name).joined(separator: ", ") : nil

		do {
			createdChannel = try await repository.createChannel(members: Array(selectedIDs), name: name)
		} catch {
			errorMessage = (error as? AuthError)?.errorDescription ?? error.localizedDescription
		}
	}
}
