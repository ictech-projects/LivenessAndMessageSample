//
//  FontRegistrar.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/26.
//

import CoreText
import Foundation

/// Registers the bundled Montserrat fonts at runtime.
///
/// The app target generates its own Info.plist (`GENERATE_INFOPLIST_FILE = YES`),
/// so there is no `UIAppFonts` array to declare the fonts. Registering them
/// programmatically at launch keeps `Font.baseStyle(...)` working everywhere.
enum FontRegistrar {

	private static let fontFileNames = [
		"Montserrat-Light",
		"Montserrat-Regular",
		"Montserrat-Medium",
		"Montserrat-Bold"
	]

	static func registerAll() {
		for name in fontFileNames {
			register(name)
		}
	}

	private static func register(_ fileName: String) {
		guard let url = Bundle.main.url(forResource: fileName, withExtension: "ttf") else {
			#if DEBUG
			print("⚠️ Font \(fileName).ttf not found in bundle.")
			#endif
			return
		}

		var error: Unmanaged<CFError>?
		if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
			#if DEBUG
			// Already-registered is fine; only log genuinely unexpected failures.
			if let cfError = error?.takeRetainedValue(),
			   CFErrorGetCode(cfError) != CTFontManagerError.alreadyRegistered.rawValue {
				print("⚠️ Failed to register \(fileName): \(cfError)")
			}
			#endif
		}
	}
}
