//
//  LivenessViewModel.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import Combine
import CoreGraphics
import Foundation

@MainActor
final class LivenessViewModel: ObservableObject {

	enum Phase: Equatable {
		case positioning
		case running
		case success
		case failed
	}

	@Published private(set) var phase: Phase = .positioning
	@Published private(set) var challenges: [LivenessChallenge]
	@Published private(set) var currentIndex = 0
	@Published private(set) var statusText = "Position your face inside the circle"
	@Published private(set) var faceInFrame = false
	/// True while the "clear face / no accessories" check is failing, so the UI
	/// can highlight the message.
	@Published private(set) var showsAccessoryWarning = false

	let camera: CameraSessionManager

	/// Called once every challenge is completed, with the captured liveness
	/// selfie (upright, mirrored) when available.
	var onSuccess: ((CGImage?) -> Void)?
	/// Called when the user backs out of the flow.
	var onCancel: (() -> Void)?

	// Per-challenge tracking.
	private var eyesWereOpen = false
	private var satisfiedStreak = 0

	/// Consecutive positive frames required for pose/smile challenges (blink is
	/// edge-triggered so it ignores this).
	private let requiredStreak = 3

	// Accessory / clear-face gate.
	private var clearFrameStreak = 0
	/// Consecutive frames an accessory has been detected — debounced so a single
	/// spurious classifier spike doesn't stall a clear face.
	private var accessoryStreak = 0
	private let accessoryDebounce = 3
	/// Consecutive non-frontal frames before the "look straight" rule fires.
	private var nonFrontalStreak = 0
	private let frontalDebounce = 3
	/// Consecutive clear, frontal, unobstructed frames required before the
	/// challenge sequence is allowed to start.
	private let requiredClearFrames = 5
	/// Max |yaw| (degrees) for a face to count as facing the camera. Missing
	/// angles are treated as frontal so a device that omits them never hard-blocks.
	private let frontalAngleLimit: Float = 22
	/// Roll (head tilt) is more prone to orientation misreads, so it's checked
	/// with a wider tolerance than yaw.
	private let rollLimit: Float = 32
	/// Both eyes reading below this are treated as clearly closed / occluded
	/// (sunglasses). A `nil` reading is NOT treated as occluded.
	private let eyesClosedThreshold: Float = 0.15
	/// Below this face-size fraction we ask the user to move closer.
	private let minFaceRatio: Float = 0.18

	// Dedicated accessory-model thresholds (Apple Vision confidences). The
	// generic classifier over-triggers on face close-ups, so keep these high to
	// avoid false "remove your hat/glasses" blocks; calibrate with the
	// `🕶️ accessory` DEBUG logs on a real device.
	private let glassesThreshold: Float = 0.5
	private let hatThreshold: Float = 0.5
	private let maskThreshold: Float = 0.5

	#if DEBUG
	private var lastPositioningLog = ""
	#endif

	init(
		challenges: [LivenessChallenge] = LivenessChallenge.randomSequence(),
		camera: CameraSessionManager = CameraSessionManager()
	) {
		self.challenges = challenges
		self.camera = camera
		self.camera.onSignals = { [weak self] signals in
			self?.handle(signals)
		}
	}

	var currentChallenge: LivenessChallenge? {
		challenges.indices.contains(currentIndex) ? challenges[currentIndex] : nil
	}

	var progress: Double {
		guard !challenges.isEmpty else { return 0 }
		return Double(currentIndex) / Double(challenges.count)
	}

	var isCameraDenied: Bool { camera.setupState == .denied }
	var isCameraFailed: Bool { camera.setupState == .failed }

	func onAppear() async {
		await camera.start()
	}

	func onDisappear() {
		camera.stop()
	}

	func cancel() {
		camera.stop()
		onCancel?()
	}

	#if targetEnvironment(simulator)
	/// The iOS Simulator has no camera, so the real liveness check can't run.
	/// This lets the auth flow be exercised end-to-end on the Simulator; it is
	/// compiled out of device and App Store builds.
	func simulatePass() {
		let selfie = camera.snapshot()
		camera.stop()
		phase = .success
		statusText = "Simulated pass"
		Task { [weak self] in
			try? await Task.sleep(for: .seconds(0.4))
			self?.onSuccess?(selfie)
		}
	}
	#endif

	// MARK: - Frame handling

	private func handle(_ signals: FaceSignals) {
		guard phase == .positioning || phase == .running else { return }

		faceInFrame = signals.hasFace && !signals.multipleFaces

		if signals.multipleFaces {
			statusText = "Make sure only your face is in frame"
			clearFrameStreak = 0
			return
		}

		guard signals.hasFace else {
			statusText = "Position your face inside the circle"
			clearFrameStreak = 0
			return
		}

		if let ratio = signals.faceBoxRatio, ratio < minFaceRatio {
			statusText = "Move a little closer"
			clearFrameStreak = 0
			return
		}

		if phase == .positioning {
			handlePositioning(signals)
			return
		}

		// While running, if the user is frontal and an accessory/occlusion is
		// detected (a hat, glasses, or mask added mid-flow), send them back to
		// the clear-face gate rather than letting a challenge slip through.
		if isFrontal(signals), hasAccessoryOrOcclusion(signals) {
			returnToClearFaceGate()
			return
		}

		guard let challenge = currentChallenge else { return }

		if isSatisfied(challenge, signals) {
			advance()
		} else {
			showsAccessoryWarning = false
			statusText = challenge.instruction
		}
	}

	// MARK: - Accessory / clear-face gate

	/// Positioning phase: require a frontal, unobstructed face held for a few
	/// frames before any challenge can start. This is where the "no accessories"
	/// rule is enforced.
	private func handlePositioning(_ signals: FaceSignals) {
		logPositioning(signals)

		// Rule: face the camera (yaw/roll are nil-safe + lenient so a normal
		// straight face is never permanently blocked, but turning away is).
		if !isFrontal(signals) {
			nonFrontalStreak += 1
			if nonFrontalStreak >= frontalDebounce {
				clearFrameStreak = 0
				accessoryStreak = 0
				showsAccessoryWarning = false
				statusText = "Look straight at the camera"
				return
			}
		} else {
			nonFrontalStreak = 0
		}

		// Rule: no accessories (mask / glasses / hat). Debounced so a single
		// spurious classifier spike can't stall a clear face, but a real one
		// (detected across frames) blocks.
		let issue = accessoryIssue(signals)
		accessoryStreak = (issue != nil) ? accessoryStreak + 1 : 0

		if let issue, accessoryStreak >= accessoryDebounce {
			showsAccessoryWarning = true
			clearFrameStreak = 0
			statusText = issue
			return
		}

		showsAccessoryWarning = false
		clearFrameStreak += 1

		if clearFrameStreak >= requiredClearFrames {
			startChallenges()
		} else {
			statusText = "Hold still — checking your face"
		}
	}

	/// Returns a user-facing message if an accessory/occlusion is detected on a
	/// frontal face, or `nil` if the face is clear. Assumes the caller already
	/// confirmed the face is frontal.
	private func accessoryIssue(_ signals: FaceSignals) -> String? {
		// 1) Dedicated accessory model (Apple Vision) — the only stage that can
		//    flag hats / clear glasses, and it flags masks too.
		if let accessory = signals.accessory {
			if accessory.hat >= hatThreshold {
				return "Please remove your hat or cap"
			}
			if accessory.glasses >= glassesThreshold {
				return "Please remove your glasses"
			}
			if accessory.mask >= maskThreshold {
				return "Please remove your mask so your whole face is visible"
			}
		}

		// 2) Sunglasses fallback — only when BOTH eyes read clearly closed. A nil
		//    reading means "classifier unsure", NOT occluded, so we don't block on
		//    it (that was making the flow never start).
		if let left = signals.leftEyeOpen, let right = signals.rightEyeOpen,
		   left < eyesClosedThreshold, right < eyesClosedThreshold {
			return "Keep both eyes open and remove sunglasses"
		}
		return nil
	}

	private func hasAccessoryOrOcclusion(_ signals: FaceSignals) -> Bool {
		guard let accessory = signals.accessory else { return false }
		return accessory.hat >= hatThreshold
			|| accessory.glasses >= glassesThreshold
			|| accessory.mask >= maskThreshold
	}

	private func isFrontal(_ signals: FaceSignals) -> Bool {
		// Missing angles → treat as frontal (0) so we never hard-block when a
		// device doesn't report head euler angles.
		abs(signals.headYaw ?? 0) < frontalAngleLimit
			&& abs(signals.headRoll ?? 0) < rollLimit
	}

	private func returnToClearFaceGate() {
		phase = .positioning
		clearFrameStreak = 0
		satisfiedStreak = 0
		eyesWereOpen = false
		showsAccessoryWarning = true
		statusText = "Keep your face clear — remove glasses, hats, or masks"
	}

	private func logPositioning(_ s: FaceSignals) {
		#if DEBUG
		let line = String(
			format: "yaw:%@ roll:%@ ratio:%@ L:%@ R:%@ smile:%@ glasses:%.2f hat:%.2f mask:%.2f",
			s.headYaw.map { String(format: "%.0f", $0) } ?? "nil",
			s.headRoll.map { String(format: "%.0f", $0) } ?? "nil",
			s.faceBoxRatio.map { String(format: "%.2f", $0) } ?? "nil",
			s.leftEyeOpen.map { String(format: "%.2f", $0) } ?? "nil",
			s.rightEyeOpen.map { String(format: "%.2f", $0) } ?? "nil",
			s.smiling.map { String(format: "%.2f", $0) } ?? "nil",
			s.accessory?.glasses ?? 0, s.accessory?.hat ?? 0, s.accessory?.mask ?? 0
		)
		if line != lastPositioningLog {
			lastPositioningLog = line
			print("🧭 positioning — \(line)")
		}
		#endif
	}

	private func startChallenges() {
		phase = .running
		satisfiedStreak = 0
		eyesWereOpen = false
		showsAccessoryWarning = false
		statusText = currentChallenge?.instruction ?? ""
		#if DEBUG
		print("✅ liveness — clear face confirmed, starting challenges: \(challenges.map(\.rawValue))")
		#endif
	}

	private func isSatisfied(_ challenge: LivenessChallenge, _ signals: FaceSignals) -> Bool {
		switch challenge {
		case .blink:
			// Edge-triggered: eyes must open, then close.
			let left = signals.leftEyeOpen ?? 1
			let right = signals.rightEyeOpen ?? 1
			if left > 0.7 && right > 0.7 { eyesWereOpen = true }
			return eyesWereOpen && left < 0.25 && right < 0.25

		case .smile:
			return streak(satisfied: (signals.smiling ?? 0) > 0.6)

		case .turnLeft:
			// The user turning their head to THEIR left reads as negative yaw on
			// the mirrored front camera.
			return streak(satisfied: (signals.headYaw ?? 0) < -18)

		case .turnRight:
			return streak(satisfied: (signals.headYaw ?? 0) > 18)
		}
	}

	/// Requires `requiredStreak` consecutive positive frames to debounce noise.
	private func streak(satisfied: Bool) -> Bool {
		satisfiedStreak = satisfied ? satisfiedStreak + 1 : 0
		return satisfiedStreak >= requiredStreak
	}

	private func advance() {
		eyesWereOpen = false
		satisfiedStreak = 0
		currentIndex += 1

		if currentIndex >= challenges.count {
			phase = .success
			statusText = "You're verified!"
			let selfie = camera.snapshot()
			camera.stop()
			Task { [weak self] in
				try? await Task.sleep(for: .seconds(0.8))
				self?.onSuccess?(selfie)
			}
		} else {
			statusText = currentChallenge?.instruction ?? ""
		}
	}
}
