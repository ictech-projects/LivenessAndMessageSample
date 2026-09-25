//
//  LivenessChallenge.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import Foundation

/// A single active-liveness action the user must perform on camera.
///
/// Randomising the order of these each session is what defeats a static photo
/// or a pre-recorded video replay.
enum LivenessChallenge: String, CaseIterable, Identifiable, Equatable {
	case blink
	case smile
	case turnLeft
	case turnRight

	var id: String { rawValue }

	/// Short imperative shown to the user.
	var instruction: String {
		switch self {
		case .blink: return "Blink your eyes"
		case .smile: return "Give us a smile"
		case .turnLeft: return "Slowly turn your head left"
		case .turnRight: return "Slowly turn your head right"
		}
	}

	var systemImageName: String {
		switch self {
		case .blink: return "eye"
		case .smile: return "face.smiling"
		case .turnLeft: return "arrow.turn.up.left"
		case .turnRight: return "arrow.turn.up.right"
		}
	}

	/// A randomised sequence of `count` distinct challenges that ALWAYS ends with
	/// `.smile` — the other challenges are shuffled into the leading slots.
	nonisolated static func randomSequence(count: Int = 3) -> [LivenessChallenge] {
		let others = allCases.filter { $0 != .smile }.shuffled()
		let leading = Array(others.prefix(max(0, count - 1)))
		return leading + [.smile]
	}
}
