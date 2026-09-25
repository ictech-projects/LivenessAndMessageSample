//
//  ChatConversationView.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 25/09/26.
//

import AVKit
import CoreTransferable
import PhotosUI
import StreamChat
import SwiftUI
import UniformTypeIdentifiers

/// A single conversation: message transcript + composer, backed by Stream Chat.
/// Supports sending text, images, videos, and voice messages.
struct ChatConversationView: View {

	@StateObject private var viewModel: ChatConversationViewModel
	@StateObject private var recorder = VoiceRecorder()

	@State private var photoItem: PhotosPickerItem?
	@State private var showMicDenied = false
	@State private var preview: MediaPreview?

	init(channelID: ChannelId) {
		_viewModel = StateObject(
			wrappedValue: ChatConversationViewModel(channelID: channelID)
		)
	}

	var body: some View {
		VStack(spacing: 0) {
			transcript
			Divider().overlay(Color.neutral30)
			composer
		}
		.background(Color(.systemBackground))
		.navigationTitle(viewModel.title)
		.navigationBarTitleDisplayMode(.inline)
		.onChange(of: photoItem) { _, item in
			guard let item else { return }
			Task {
				let isVideo = item.supportedContentTypes.contains {
					$0.conforms(to: .movie) || $0.conforms(to: .video)
				}
				if isVideo {
					if let movie = try? await item.loadTransferable(type: Movie.self) {
						viewModel.sendVideo(url: movie.url)
					}
				} else if let data = try? await item.loadTransferable(type: Data.self) {
					viewModel.sendImage(data)
				}
				photoItem = nil
			}
		}
		.fullScreenCover(item: $preview) { item in
			MediaPreviewView(item: item)
		}
		.alert("Microphone access needed", isPresented: $showMicDenied) {
			Button("OK", role: .cancel) {}
		} message: {
			Text("Enable microphone access in Settings to record voice messages.")
		}
	}

	private var transcript: some View {
		ScrollViewReader { proxy in
			ScrollView {
				LazyVStack(spacing: 8) {
					if viewModel.isLoading {
						ProgressView().padding(.top, 24)
					} else if viewModel.messages.isEmpty {
						emptyState
					}

					ForEach(viewModel.messages, id: \.id) { message in
						MessageBubble(message: message) { preview = $0 }
							.id(message.id)
							.onAppear { viewModel.loadMoreIfNeeded(currentMessage: message) }
					}
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 12)
			}
			.onChange(of: viewModel.messages.count) {
				if let last = viewModel.messages.last?.id {
					withAnimation(.easeOut(duration: 0.2)) {
						proxy.scrollTo(last, anchor: .bottom)
					}
				}
			}
		}
	}

	private var emptyState: some View {
		VStack(spacing: 8) {
			Image(systemName: "bubble.left.and.bubble.right")
				.font(.system(size: 36))
				.foregroundStyle(.neutral60)
			Text(viewModel.errorMessage ?? "Say hello 👋")
				.font(.baseStyle(size: 14, weight: .regular))
				.foregroundStyle(.neutral70)
				.multilineTextAlignment(.center)
		}
		.padding(.top, 60)
	}

	@ViewBuilder
	private var composer: some View {
		if recorder.isRecording {
			recordingBar
		} else {
			defaultComposer
		}
	}

	private var defaultComposer: some View {
		HStack(spacing: 10) {
			PhotosPicker(
				selection: $photoItem,
				matching: .any(of: [.images, .videos]),
				photoLibrary: .shared()
			) {
				Image(systemName: "photo.on.rectangle")
					.font(.system(size: 22))
					.foregroundStyle(Color.brandSecondary)
			}
			.accessibilityLabel("Send photo or video")

			TextField("Message", text: $viewModel.draft, axis: .vertical)
				.font(.baseStyle(size: 16, weight: .regular))
				.foregroundStyle(.neutral90)
				.lineLimit(1...4)
				.padding(.horizontal, 14)
				.padding(.vertical, 10)
				.background(RoundedRectangle(cornerRadius: 20).fill(Color.neutral20))
				.overlay {
					RoundedRectangle(cornerRadius: 20).stroke(Color.neutral40, lineWidth: 1)
				}

			if canSendText {
				Button {
					viewModel.send()
				} label: {
					Image(systemName: "arrow.up.circle.fill")
						.font(.system(size: 32))
						.foregroundStyle(Color.brandSecondary)
				}
			} else {
				Button {
					startRecording()
				} label: {
					Image(systemName: "mic.fill")
						.font(.system(size: 24))
						.foregroundStyle(Color.brandSecondary)
						.frame(width: 32, height: 32)
				}
				.accessibilityLabel("Record voice message")
			}
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 10)
		.background(Color(.systemBackground))
	}

	private var recordingBar: some View {
		HStack(spacing: 14) {
			Button {
				recorder.cancel()
			} label: {
				Image(systemName: "trash")
					.font(.system(size: 20))
					.foregroundStyle(.neutral70)
			}
			.accessibilityLabel("Discard recording")

			HStack(spacing: 8) {
				Circle().fill(Color.red).frame(width: 10, height: 10)
				Text(Self.timeString(recorder.elapsed))
					.font(.baseStyle(size: 16, weight: .medium))
					.foregroundStyle(.neutral90)
					.monospacedDigit()
				Text("Recording…")
					.font(.baseStyle(size: 14, weight: .regular))
					.foregroundStyle(.neutral60)
			}
			.frame(maxWidth: .infinity, alignment: .leading)

			Button {
				if let result = recorder.stop() {
					viewModel.sendVoiceRecording(url: result.url, duration: result.duration)
				}
			} label: {
				Image(systemName: "arrow.up.circle.fill")
					.font(.system(size: 32))
					.foregroundStyle(Color.brandSecondary)
			}
			.accessibilityLabel("Send voice message")
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 10)
		.background(Color(.systemBackground))
	}

	private var canSendText: Bool {
		!viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	private func startRecording() {
		Task {
			guard await recorder.requestPermission() else {
				showMicDenied = true
				return
			}
			recorder.start()
		}
	}

	static func timeString(_ seconds: TimeInterval) -> String {
		let total = Int(seconds)
		return String(format: "%d:%02d", total / 60, total % 60)
	}
}

// MARK: - Bubble

private struct MessageBubble: View {
	let message: ChatMessage
	let onPreview: (MediaPreview) -> Void

	private var isMine: Bool { message.isSentByCurrentUser }

	var body: some View {
		HStack {
			if isMine { Spacer(minLength: 48) }

			VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
				if !isMine, let name = message.author.name, !name.isEmpty {
					Text(name)
						.font(.baseStyle(size: 11, weight: .medium))
						.foregroundStyle(.neutral60)
				}

				ForEach(message.imageAttachments, id: \.id) { attachment in
					ImageAttachmentView(url: attachment.imageURL)
						.onTapGesture { onPreview(.image(attachment.imageURL)) }
				}

				ForEach(message.videoAttachments, id: \.id) { attachment in
					VideoAttachmentView(thumbnailURL: attachment.thumbnailURL)
						.onTapGesture { onPreview(.video(attachment.videoURL)) }
				}

				ForEach(message.voiceRecordingAttachments, id: \.id) { attachment in
					VoiceAttachmentView(
						url: attachment.voiceRecordingURL,
						duration: attachment.duration ?? 0,
						isMine: isMine
					)
				}

				if !message.text.isEmpty {
					Text(message.text)
						.font(.baseStyle(size: 15, weight: .regular))
						.foregroundStyle(isMine ? .white : .neutral90)
						.padding(.horizontal, 14)
						.padding(.vertical, 9)
						.background(
							RoundedRectangle(cornerRadius: 16)
								.fill(isMine ? Color.brandSecondary : Color.neutral20)
						)
				}
			}

			if !isMine { Spacer(minLength: 48) }
		}
		.frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
	}
}

// MARK: - Image attachment

private struct ImageAttachmentView: View {
	let url: URL

	var body: some View {
		AsyncImage(url: url) { phase in
			switch phase {
			case .success(let image):
				image.resizable().scaledToFill()
			case .failure:
				placeholder(systemName: "photo")
			case .empty:
				placeholder(systemName: nil)
			@unknown default:
				placeholder(systemName: "photo")
			}
		}
		.frame(width: 220, height: 220)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}

	private func placeholder(systemName: String?) -> some View {
		ZStack {
			Rectangle().fill(Color.neutral20)
			if let systemName {
				Image(systemName: systemName).foregroundStyle(.neutral50)
			} else {
				ProgressView()
			}
		}
	}
}

// MARK: - Voice attachment

private struct VoiceAttachmentView: View {
	let url: URL
	let duration: TimeInterval
	let isMine: Bool

	@StateObject private var player = VoiceMessagePlayer()

	private var tint: Color { isMine ? .white : .brandSecondary }
	private var textColor: Color { isMine ? .white : .neutral90 }

	var body: some View {
		HStack(spacing: 10) {
			Button {
				player.toggle(url: url)
			} label: {
				Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
					.font(.system(size: 30))
					.foregroundStyle(tint)
			}

			VStack(alignment: .leading, spacing: 4) {
				ProgressView(value: player.progress)
					.progressViewStyle(.linear)
					.tint(tint)
					.frame(width: 130)
				Text(ChatConversationView.timeString(duration))
					.font(.baseStyle(size: 12, weight: .regular))
					.foregroundStyle(textColor.opacity(0.9))
					.monospacedDigit()
			}
		}
		.padding(.horizontal, 14)
		.padding(.vertical, 10)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(isMine ? Color.brandSecondary : Color.neutral20)
		)
	}
}

// MARK: - Video attachment

private struct VideoAttachmentView: View {
	let thumbnailURL: URL?

	var body: some View {
		ZStack {
			if let thumbnailURL {
				AsyncImage(url: thumbnailURL) { image in
					image.resizable().scaledToFill()
				} placeholder: {
					Rectangle().fill(Color.black.opacity(0.85))
				}
			} else {
				Rectangle().fill(Color.black.opacity(0.85))
			}

			Image(systemName: "play.circle.fill")
				.font(.system(size: 44))
				.foregroundStyle(.white.opacity(0.95))
				.shadow(radius: 4)
		}
		.frame(width: 220, height: 220)
		.clipShape(RoundedRectangle(cornerRadius: 16))
	}
}

// MARK: - Full-screen media preview

enum MediaPreview: Identifiable {
	case image(URL)
	case video(URL)

	var id: String {
		switch self {
		case .image(let url): return "image-\(url.absoluteString)"
		case .video(let url): return "video-\(url.absoluteString)"
		}
	}
}

private struct MediaPreviewView: View {
	let item: MediaPreview
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		ZStack {
			Color.black.ignoresSafeArea()

			switch item {
			case .image(let url):
				ZoomableImage(url: url)
			case .video(let url):
				VideoPlayer(player: AVPlayer(url: url))
					.ignoresSafeArea()
					.onAppear {
						try? AVAudioSession.sharedInstance().setCategory(.playback)
						try? AVAudioSession.sharedInstance().setActive(true)
					}
			}

			VStack {
				HStack {
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark")
							.font(.system(size: 16, weight: .bold))
							.foregroundStyle(.white)
							.frame(width: 40, height: 40)
							.background(Circle().fill(.white.opacity(0.18)))
					}
					.accessibilityLabel("Close")
					Spacer()
				}
				Spacer()
			}
			.padding(.horizontal, 20)
			.padding(.top, 12)
		}
	}
}

/// Pinch-to-zoom + drag image viewer.
private struct ZoomableImage: View {
	let url: URL
	@State private var scale: CGFloat = 1
	@State private var offset: CGSize = .zero

	var body: some View {
		AsyncImage(url: url) { phase in
			switch phase {
			case .success(let image):
				image
					.resizable()
					.scaledToFit()
					.scaleEffect(scale)
					.offset(offset)
					.gesture(
						MagnifyGesture()
							.onChanged { scale = max(1, $0.magnification) }
							.onEnded { _ in withAnimation(.spring) { scale = max(1, scale); if scale == 1 { offset = .zero } } }
					)
					.simultaneousGesture(
						DragGesture()
							.onChanged { if scale > 1 { offset = $0.translation } }
							.onEnded { _ in if scale <= 1 { withAnimation(.spring) { offset = .zero } } }
					)
					.onTapGesture(count: 2) {
						withAnimation(.spring) {
							scale = scale > 1 ? 1 : 2
							offset = .zero
						}
					}
			case .failure:
				Image(systemName: "photo")
					.font(.system(size: 48))
					.foregroundStyle(.white.opacity(0.7))
			default:
				ProgressView().tint(.white)
			}
		}
	}
}

// MARK: - Transferable video for PhotosPicker

/// Loads a picked video into a temporary file URL for uploading.
struct Movie: Transferable {
	let url: URL

	static var transferRepresentation: some TransferRepresentation {
		FileRepresentation(contentType: .movie) { movie in
			SentTransferredFile(movie.url)
		} importing: { received in
			let dest = FileManager.default.temporaryDirectory
				.appendingPathComponent("video-\(UUID().uuidString).mov")
			try? FileManager.default.removeItem(at: dest)
			try FileManager.default.copyItem(at: received.file, to: dest)
			return Movie(url: dest)
		}
	}
}
