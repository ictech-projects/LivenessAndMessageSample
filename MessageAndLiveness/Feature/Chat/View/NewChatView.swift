//
//  NewChatView.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 24/09/26.
//

import SwiftUI

/// Pick one or more people, then create (or fetch) a chat with them.
/// On success it hands the created channel back to the caller via `onCreated`.
struct NewChatView: View {

	@Environment(\.dismiss) private var dismiss
	@StateObject private var viewModel = NewChatViewModel()

	/// Called with the freshly created/fetched channel once creation succeeds.
	let onCreated: (ChannelSummary) -> Void

	var body: some View {
		NavigationStack {
			Group {
				if viewModel.isLoading && viewModel.users.isEmpty {
					ProgressView().controlSize(.large).tint(.brandSecondary)
						.frame(maxWidth: .infinity, maxHeight: .infinity)
				} else if viewModel.users.isEmpty {
					emptyState
				} else {
					directory
				}
			}
			.background(Color(.systemBackground))
			.navigationTitle("New chat")
			.navigationBarTitleDisplayMode(.inline)
			.searchable(text: $viewModel.searchText, prompt: "Search people")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") { dismiss() }
						.foregroundStyle(.neutral70)
				}
				ToolbarItem(placement: .confirmationAction) {
					Button {
						Task { await viewModel.createChannel() }
					} label: {
						if viewModel.isCreating {
							ProgressView()
						} else {
							Text("Start")
								.font(.baseStyle(size: 16, weight: .bold))
						}
					}
					.disabled(!viewModel.canCreate)
				}
			}
			.task { await viewModel.load() }
			.onChange(of: viewModel.createdChannel) { _, channel in
				if let channel {
					onCreated(channel)
					dismiss()
				}
			}
		}
	}

	private var directory: some View {
		List {
			ForEach(viewModel.filteredUsers) { user in
				Button {
					viewModel.toggle(user)
				} label: {
					UserRow(user: user, isSelected: viewModel.selectedIDs.contains(user.id))
				}
				.listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
				.listRowSeparatorTint(.neutral40)
			}
		}
		.listStyle(.plain)
	}

	private var emptyState: some View {
		VStack(spacing: 10) {
			Image(systemName: "person.2")
				.font(.system(size: 40))
				.foregroundStyle(.neutral60)
			Text(viewModel.errorMessage ?? "No people to chat with yet.")
				.font(.baseStyle(size: 14, weight: .regular))
				.foregroundStyle(.neutral70)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

// MARK: - Row

private struct UserRow: View {
	let user: DirectoryUser
	let isSelected: Bool

	var body: some View {
		HStack(spacing: 12) {
			Text(user.initials)
				.font(.baseStyle(size: 15, weight: .bold))
				.foregroundStyle(.white)
				.frame(width: 44, height: 44)
				.background(Circle().fill(Color.brandSecondary))

			Text(user.name)
				.font(.baseStyle(size: 16, weight: .medium))
				.foregroundStyle(.neutral90)

			Spacer()

			Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
				.font(.system(size: 22))
				.foregroundStyle(isSelected ? Color.brandSecondary : Color.neutral40)
		}
		.padding(.vertical, 4)
		.contentShape(Rectangle())
	}
}
