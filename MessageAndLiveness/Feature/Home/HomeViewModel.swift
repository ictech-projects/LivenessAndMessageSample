//
//  HomeViewModel.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 25/09/26.
//
//  Live chat inbox backed by Stream's `ChatChannelListController`: the list
//  auto-updates on new messages/channels and exposes per-channel unread counts.
//

import Combine
import Foundation
import StreamChat

@MainActor
final class HomeViewModel: ObservableObject {

	@Published private(set) var channels: [ChatChannel] = []
	@Published private(set) var isLoading = true
	@Published var errorMessage: String?

	private var controller: ChatChannelListController?
	private var connectionObserver: AnyCancellable?
	/// Holds channel controllers alive while a delete/hide request is in flight.
	private var pendingDeletes: [ChannelId: ChatChannelController] = [:]

	/// Starts observing the signed-in user's channels. Waits for the Stream
	/// client to finish connecting if it isn't ready yet.
	func start() {
		guard controller == nil else { return }
		if StreamChatService.shared.isConnected {
			setup()
		} else {
			isLoading = true
			connectionObserver = StreamChatService.shared.$isConnected
				.receive(on: DispatchQueue.main)
				.sink { [weak self] connected in
					if connected { self?.setup() }
				}
		}
	}

	/// Pull-to-refresh — re-syncs from the server (list also updates live).
	func refresh() async {
		await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
			guard let controller else { continuation.resume(); return }
			controller.synchronize { _ in continuation.resume() }
		}
	}

	/// Deletes the conversation. Falls back to hiding it from this user's list
	/// if the account lacks channel-delete permission. The live list removes the
	/// row automatically once the change lands.
	func deleteChannel(_ cid: ChannelId) {
		guard pendingDeletes[cid] == nil, let client = StreamChatService.shared.client else { return }
		let controller = client.channelController(for: cid)
		pendingDeletes[cid] = controller

		controller.deleteChannel { [weak self] error in
			Task { @MainActor in
				guard let self else { return }
				guard error != nil else {
					self.pendingDeletes[cid] = nil
					return
				}
				// No delete permission — remove it from this user's list instead.
				controller.hideChannel(clearHistory: true) { [weak self] hideError in
					Task { @MainActor in
						guard let self else { return }
						if let hideError { self.errorMessage = hideError.localizedDescription }
						self.pendingDeletes[cid] = nil
					}
				}
			}
		}
	}

	private func setup() {
		guard controller == nil,
			  let client = StreamChatService.shared.client,
			  let userID = client.currentUserId else { return }

		connectionObserver?.cancel()
		connectionObserver = nil

		let query = ChannelListQuery(
			filter: .in(.members, values: [userID]),
			sort: [.init(key: .lastMessageAt, isAscending: false)]
		)
		let controller = client.channelListController(query: query)
		self.controller = controller
		controller.delegate = self
		controller.synchronize { [weak self] error in
			Task { @MainActor in
				guard let self else { return }
				self.isLoading = false
				if let error { self.errorMessage = error.localizedDescription }
				self.reload()
			}
		}
	}

	private func reload() {
		let all = controller?.channels ?? []
		// Collapse conversations that resolve to the same partner (member id) or
		// the same channel name into a single row. The list is already sorted by
		// most-recent activity, so the first occurrence per key is the one kept.
		var seen = Set<String>()
		var deduped: [ChatChannel] = []
		for channel in all where seen.insert(dedupeKey(for: channel)).inserted {
			deduped.append(channel)
		}
		channels = deduped
	}

	/// Identity used to merge duplicate chats: an explicit name, otherwise the
	/// other participants' ids.
	private func dedupeKey(for channel: ChatChannel) -> String {
		if let name = channel.name, !name.isEmpty {
			return "name:" + name.lowercased()
		}
		return "members:" + otherMemberIDs(of: channel).joined(separator: ",")
	}

	/// Returns an already-open chat that matches the just-created one — same
	/// Stream channel (backend get-or-create for the same participant) or the
	/// same displayed name/participant — so the caller can route to it instead
	/// of opening a duplicate.
	func existingChannelID(matching summary: ChannelSummary, currentUserID birchUserID: Int?) -> ChannelId? {
		// "Same id": the backend returns the existing channel for the same
		// participant, so its Stream id is already in the list.
		if let byID = channels.first(where: { $0.cid.id == summary.streamChannelId }) {
			return byID.cid
		}
		// "Same name": match by the displayed conversation title.
		let target = summary.title(currentUserID: birchUserID).lowercased()
		guard !target.isEmpty else { return nil }
		let me = StreamChatService.shared.client?.currentUserId
		return channels.first { title(of: $0, me: me).lowercased() == target }?.cid
	}

	private func otherMemberIDs(of channel: ChatChannel) -> [String] {
		let me = StreamChatService.shared.client?.currentUserId
		return channel.lastActiveMembers.map(\.id).filter { $0 != me }.sorted()
	}

	private func title(of channel: ChatChannel, me: String?) -> String {
		if let name = channel.name, !name.isEmpty { return name }
		let others = channel.lastActiveMembers.filter { $0.id != me }
		let names = others.compactMap { $0.name ?? $0.id }
		return names.isEmpty ? "Chat" : names.joined(separator: ", ")
	}
}

extension HomeViewModel: ChatChannelListControllerDelegate {
	nonisolated func controller(
		_ controller: ChatChannelListController,
		didChangeChannels changes: [ListChange<ChatChannel>]
	) {
		Task { @MainActor in self.reload() }
	}
}
