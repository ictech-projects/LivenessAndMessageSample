//
//  UIApplication+version.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 09/02/26.
//

import Foundation
import SwiftUI

extension UIApplication {
	static var appVersion: String? {
		// "CFBundleShortVersionString" is the marketing version number (e.g., "1.0.0")
		return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
	}
	
	static var appBuild: String? {
		// "CFBundleVersion" is the build number (e.g., "42")
		return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
	}
}
