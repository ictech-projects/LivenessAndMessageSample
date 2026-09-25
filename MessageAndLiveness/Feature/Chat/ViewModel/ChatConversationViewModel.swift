//
//  ChatConversationViewModel.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 25/09/26.
//
//  Drives one conversation via the Stream Chat `ChatChannelController`:
//  synchronises the channel, republishes its messages, and sends new ones.
//

import Combine
import Foundation
import StreamChat

@MainActor
final class ChatConversationViewModel: ObservableObject {

	@Published private(set) var messages: [ChatMessage] = []
	@Published private(set) var isLoading = true
	@Published var errorMessage: String?
	@Published var draft = ""
	@Published private(set) var title = "Chat"

	private var controller: ChatChannelController?

	init(channelID: ChannelId) {
		guard let client = StreamChatService.shared.client else {
			isLoading = false
			errorMessage = "Chat isn't connected. Please sign in again."
			return
		}

		let controller = client.channelController(for: channelID)
		self.controller = controller
		controller.delegate = self
		controller.synchronize { [weak self] error in
			Task { @MainActor in
				guard let self else { return }
				self.isLoading = false
				if let error {
					self.errorMessage = error.localizedDescription
				}
				self.updateTitle()
				self.markRead()
				self.reload()
			}
		}
	}

	/// Derives the conversation title from the Stream channel (explicit name,
	/// else the other members' names).
	private func updateTitle() {
		guard let channel = controller?.channel else { return }
		if let name = channel.name, !name.isEmpty {
			title = name
			return
		}
		let me = StreamChatService.shared.client?.currentUserId
		let others = channel.lastActiveMembers.filter { $0.id != me }
		let names = others.compactMap { $0.name ?? $0.id }
		title = names.isEmpty ? "Chat" : names.joined(separator: ", ")
	}

	/// Marks the channel read so its unread badge clears in the chat list.
	private func markRead() {
		controller?.markRead()
	}

	func send() {
		let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !text.isEmpty else { return }
		controller?.createNewMessage(text: text)
		draft = ""
	}

	/// Sends a picked image. Stream uploads the local file, then swaps in the
	/// remote URL automatically.
	func sendImage(_ data: Data) {
		guard let controller else { return }
		let url = FileManager.default.temporaryDirectory
			.appendingPathComponent("image-\(UUID().uuidString).jpg")
		do {
			try data.write(to: url)
			let attachment = try AnyAttachmentPayload(localFileURL: url, attachmentType: .image)
			controller.createNewMessage(text: "", attachments: [attachment])
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	/// Sends a picked video as a `.video` attachment.
	func sendVideo(url: URL) {
		guard let controller else { return }
		do {
			let attachment = try AnyAttachmentPayload(localFileURL: url, attachmentType: .video)
			controller.createNewMessage(text: "", attachments: [attachment])
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	/// Sends a recorded voice message as a `.voiceRecording` attachment.
	func sendVoiceRecording(url: URL, duration: TimeInterval) {
		guard let controller else { return }
		do {
			var metadata = AnyAttachmentLocalMetadata()
			metadata.duration = duration
			let attachment = try AnyAttachmentPayload(
				localFileURL: url,
				attachmentType: .voiceRecording,
				localMetadata: metadata
			)
			controller.createNewMessage(text: "", attachments: [attachment])
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	func loadMoreIfNeeded(currentMessage: ChatMessage) {
		// The list shows oldest→newest, so the first row is the oldest loaded.
		guard currentMessage.id == messages.first?.id else { return }
		controller?.loadPreviousMessages()
	}

	private func reload() {
		// The controller keeps messages newest-first; reverse for a top-to-bottom
		// transcript.
		messages = Array(controller?.messages ?? []).reversed()
	}
}

extension ChatConversationViewModel: ChatChannelControllerDelegate {
	nonisolated func channelController(
		_ channelController: ChatChannelController,
		didUpdateMessages changes: [ListChange<ChatMessage>]
	) {
		Task { @MainActor in
			self.reload()
			// New messages arrived while the conversation is on screen — keep it read.
			self.markRead()
		}
	}
}
