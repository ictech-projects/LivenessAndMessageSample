//
//  VoiceMessagePlayer.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 25/09/26.
//
//  Plays a single voice-message URL (local or remote) with play/pause and a
//  progress fraction, for rendering inside a chat bubble.
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class VoiceMessagePlayer: ObservableObject {

	@Published private(set) var isPlaying = false
	@Published private(set) var progress: Double = 0

	private var player: AVPlayer?
	private var timeObserver: Any?
	private var endObserver: NSObjectProtocol?

	func toggle(url: URL) {
		if isPlaying {
			pause()
		} else {
			play(url: url)
		}
	}

	private func play(url: URL) {
		if player == nil {
			let player = AVPlayer(url: url)
			self.player = player
			addObservers(to: player)
		}
		try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
		try? AVAudioSession.sharedInstance().setActive(true)
		player?.play()
		isPlaying = true
	}

	func pause() {
		player?.pause()
		isPlaying = false
	}

	private func addObservers(to player: AVPlayer) {
		let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
		timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
			Task { @MainActor [weak self] in
				guard let self, let item = player.currentItem else { return }
				let total = item.duration.seconds
				guard total.isFinite, total > 0 else { return }
				self.progress = min(max(time.seconds / total, 0), 1)
			}
		}
		endObserver = NotificationCenter.default.addObserver(
			forName: .AVPlayerItemDidPlayToEndTime,
			object: player.currentItem,
			queue: .main
		) { [weak self] _ in
			Task { @MainActor [weak self] in
				guard let self else { return }
				self.isPlaying = false
				self.progress = 0
				self.player?.seek(to: .zero)
			}
		}
	}

	deinit {
		if let timeObserver { player?.removeTimeObserver(timeObserver) }
		if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
	}
}
