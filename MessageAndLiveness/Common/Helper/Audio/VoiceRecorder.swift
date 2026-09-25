//
//  VoiceRecorder.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 25/09/26.
//
//  Records a short voice message to a temporary .m4a file for sending as a
//  Stream `.voiceRecording` attachment. Publishes elapsed time so the composer
//  can show a live timer.
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class VoiceRecorder: NSObject, ObservableObject {

	@Published private(set) var isRecording = false
	@Published private(set) var elapsed: TimeInterval = 0

	private var recorder: AVAudioRecorder?
	private var fileURL: URL?
	private var timer: Timer?

	/// Asks for mic permission (async). Returns whether recording is allowed.
	func requestPermission() async -> Bool {
		await withCheckedContinuation { continuation in
			AVAudioApplication.requestRecordPermission { granted in
				continuation.resume(returning: granted)
			}
		}
	}

	/// Begins recording. Returns false if the session/recorder couldn't start.
	@discardableResult
	func start() -> Bool {
		guard !isRecording else { return true }

		let session = AVAudioSession.sharedInstance()
		do {
			try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
			try session.setActive(true)
		} catch {
			return false
		}

		let url = FileManager.default.temporaryDirectory
			.appendingPathComponent("voice-\(UUID().uuidString).m4a")
		let settings: [String: Any] = [
			AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
			AVSampleRateKey: 44_100,
			AVNumberOfChannelsKey: 1,
			AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
		]

		do {
			let recorder = try AVAudioRecorder(url: url, settings: settings)
			recorder.delegate = self
			guard recorder.record() else { return false }
			self.recorder = recorder
			self.fileURL = url
			isRecording = true
			elapsed = 0
			startTimer()
			return true
		} catch {
			return false
		}
	}

	/// Stops recording and returns the file + its duration, or nil if too short.
	@discardableResult
	func stop() -> (url: URL, duration: TimeInterval)? {
		guard isRecording, let recorder, let url = fileURL else {
			cleanup()
			return nil
		}
		let duration = recorder.currentTime
		recorder.stop()
		cleanup()

		// Discard sub-second taps that produce an unusable clip.
		guard duration >= 1 else {
			try? FileManager.default.removeItem(at: url)
			return nil
		}
		return (url, duration)
	}

	/// Aborts recording and deletes the partial file.
	func cancel() {
		recorder?.stop()
		if let url = fileURL { try? FileManager.default.removeItem(at: url) }
		cleanup()
	}

	private func startTimer() {
		timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
			Task { @MainActor [weak self] in
				guard let self, let recorder = self.recorder, recorder.isRecording else { return }
				self.elapsed = recorder.currentTime
			}
		}
	}

	private func cleanup() {
		timer?.invalidate()
		timer = nil
		recorder = nil
		fileURL = nil
		isRecording = false
		try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
	}
}

extension VoiceRecorder: @preconcurrency AVAudioRecorderDelegate {
	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
		// State is managed by stop()/cancel(); nothing extra needed here.
	}
}
