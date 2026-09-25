//
//  HomeView.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import StreamChat
import SwiftUI

/// Signed-in + verified landing screen: a live chat inbox backed by Stream.
/// Updates in real time and shows an unread badge per conversation.
struct HomeView: View {

	@EnvironmentObject private var session: SessionStore
	@StateObject private var viewModel = HomeViewModel()
	@State private var showNewChat = false
	@State private var selectedChannel: ChannelId?
	@State private var pendingDelete: ChannelId?
	@State private var columnVisibility: NavigationSplitViewVisibility = .all

	private var currentUserID: String? { StreamChatService.shared.client?.currentUserId }

	var body: some View {
		// Two-column layout on iPad/large widths (list ↔ conversation);
		// automatically collapses to a push-based stack on iPhone.
		NavigationSplitView(columnVisibility: $columnVisibility) {
			sidebar
				.background(Color(.systemBackground))
				.navigationTitle("Chats")
				.toolbar {
					ToolbarItem(placement: .topBarLeading) {
						Button {
							session.signOut()
						} label: {
							Image(systemName: "rectangle.portrait.and.arrow.right")
								.foregroundStyle(.brandSecondary)
						}
						.accessibilityLabel("Sign out")
					}
					ToolbarItem(placement: .topBarTrailing) {
						Button {
							showNewChat = true
						} label: {
							Image(systemName: "square.and.pencil")
								.foregroundStyle(.brandSecondary)
						}
						.accessibilityLabel("New chat")
					}
				}
				.task { viewModel.start() }
				.refreshable { await viewModel.refresh() }
				.sheet(isPresented: $showNewChat) {
					NewChatView { channel in
						// If a chat with the same participant/name already exists,
						// open it instead of a duplicate.
						selectedChannel = viewModel.existingChannelID(
							matching: channel,
							currentUserID: session.currentUser?.id
						) ?? ChannelId(type: .messaging, id: channel.streamChannelId)
					}
				}
		} detail: {
			NavigationStack {
				detail
			}
		}
		.navigationSplitViewStyle(.balanced)
	}

	@ViewBuilder
	private var sidebar: some View {
		if viewModel.isLoading && viewModel.channels.isEmpty {
			ProgressView().controlSize(.large).tint(.brandSecondary)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		} else if viewModel.channels.isEmpty {
			emptyState
		} else {
			chatList
		}
	}

	private var chatList: some View {
		List(selection: $selectedChannel) {
			ForEach(viewModel.channels, id: \.cid) { channel in
				ChatRow(channel: channel, currentUserID: currentUserID)
					.tag(channel.cid)
					.listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
					.listRowSeparatorTint(.neutral40)
					.swipeActions(edge: .trailing, allowsFullSwipe: false) {
						Button(role: .destructive) {
							pendingDelete = channel.cid
						} label: {
							Label("Delete", systemImage: "trash")
						}
					}
					.contextMenu {
						Button(role: .destructive) {
							pendingDelete = channel.cid
						} label: {
							Label("Delete chat", systemImage: "trash")
						}
					}
			}
		}
		.listStyle(.plain)
		.confirmationDialog(
			"Delete this chat?",
			isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
			titleVisibility: .visible
		) {
			Button("Delete", role: .destructive) {
				if let cid = pendingDelete {
					if selectedChannel == cid { selectedChannel = nil }
					viewModel.deleteChannel(cid)
				}
				pendingDelete = nil
			}
			Button("Cancel", role: .cancel) { pendingDelete = nil }
		} message: {
			Text("This conversation will be removed from your chats.")
		}
	}

	@ViewBuilder
	private var detail: some View {
		if let selectedChannel {
			ChatConversationView(channelID: selectedChannel)
				// Recreate the conversation (and its view model) when switching chats.
				.id(selectedChannel)
		} else {
			noSelection
		}
	}

	private var noSelection: some View {
		VStack(spacing: 14) {
			Image(systemName: "bubble.left.and.bubble.right")
				.font(.system(size: 52))
				.foregroundStyle(.neutral50)
			Text("Select a chat")
				.font(.baseStyle(size: 18, weight: .bold))
				.foregroundStyle(.neutral80)
			Text("Choose a conversation from the list, or start a new one.")
				.font(.baseStyle(size: 14, weight: .regular))
				.foregroundStyle(.neutral60)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(.systemBackground))
	}

	private var emptyState: some View {
		VStack(spacing: 14) {
			Image(systemName: "bubble.left.and.bubble.right")
				.font(.system(size: 44))
				.foregroundStyle(.neutral60)
			Text("No chats yet")
				.font(.baseStyle(size: 18, weight: .bold))
				.foregroundStyle(.neutral90)
			Text(viewModel.errorMessage ?? "Your conversations will appear here.")
				.font(.baseStyle(size: 14, weight: .regular))
				.foregroundStyle(.neutral70)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

// MARK: - Row

private struct ChatRow: View {
	let channel: ChatChannel
	let currentUserID: String?

	private var unread: Int { channel.unreadCount.messages }
	private var isUnread: Bool { unread > 0 }

	var body: some View {
		HStack(spacing: 10) {
			// Leading unread marker — a small dot, keeps its slot when read so
			// rows stay aligned.
			Circle()
				.fill(isUnread ? Color.brandSecondary : Color.clear)
				.frame(width: 8, height: 8)
				.accessibilityHidden(true)

			Text(initials)
				.font(.baseStyle(size: 16, weight: .bold))
				.foregroundStyle(.white)
				.frame(width: 48, height: 48)
				.background(Circle().fill(Color.brandSecondary))

			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.baseStyle(size: 16, weight: isUnread ? .bold : .medium))
					.foregroundStyle(.neutral90)
					.lineLimit(1)
				Text(preview)
					.font(.baseStyle(size: 14, weight: isUnread ? .medium : .regular))
					.foregroundStyle(isUnread ? .neutral90 : .neutral70)
					.lineLimit(1)
			}

			Spacer()

			VStack(alignment: .trailing, spacing: 6) {
				if let stamp = timestamp {
					Text(stamp)
						.font(.baseStyle(size: 12, weight: isUnread ? .bold : .regular))
						.foregroundStyle(isUnread ? .brandSecondary : .neutral60)
				}

				if isUnread {
					Text(unread > 99 ? "99+" : "\(unread)")
						.font(.baseStyle(size: 12, weight: .bold))
						.foregroundStyle(.white)
						.padding(.horizontal, 7)
						.frame(minWidth: 22, minHeight: 22)
						.background(Capsule().fill(Color.brandSecondary))
						.accessibilityLabel("\(unread) unread messages")
				}
			}
		}
		.padding(.vertical, 4)
		.contentShape(Rectangle())
	}

	private var title: String {
		if let name = channel.name, !name.isEmpty { return name }
		let others = channel.lastActiveMembers.filter { $0.id != currentUserID }
		let names = others.compactMap { $0.name ?? $0.id }
		return names.isEmpty ? "Chat" : names.joined(separator: ", ")
	}

	private var preview: String {
		guard let last = channel.latestMessages.max(by: { $0.createdAt < $1.createdAt }) else {
			return "Tap to open the conversation"
		}
		if !last.text.isEmpty { return last.text }
		if !last.imageAttachments.isEmpty { return "📷 Photo" }
		if !last.voiceRecordingAttachments.isEmpty { return "🎙️ Voice message" }
		return "Attachment"
	}

	private var initials: String {
		let letters = title.split(separator: " ").prefix(2).compactMap { $0.first }
		return String(letters).uppercased()
	}

	/// Relative label for the last activity: time today, "Yesterday", the
	/// weekday within a week, else a short date.
	private var timestamp: String? {
		guard let date = channel.lastMessageAt else { return nil }
		let calendar = Calendar.current
		if calendar.isDateInToday(date) {
			return Self.timeFormatter.string(from: date)
		}
		if calendar.isDateInYesterday(date) {
			return "Yesterday"
		}
		let start = calendar.startOfDay(for: date)
		let today = calendar.startOfDay(for: Date())
		if let days = calendar.dateComponents([.day], from: start, to: today).day, days < 7 {
			return Self.weekdayFormatter.string(from: date)
		}
		return Self.dateFormatter.string(from: date)
	}

	private static let timeFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.setLocalizedDateFormatFromTemplate("jmm") // e.g. 09:41 or 9:41 AM
		return formatter
	}()

	private static let weekdayFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.setLocalizedDateFormatFromTemplate("EEE") // e.g. Mon
		return formatter
	}()

	private static let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.setLocalizedDateFormatFromTemplate("ddMMyy") // e.g. 12/09/25
		return formatter
	}()
}

#Preview {
	HomeView()
		.environmentObject(SessionStore())
}
