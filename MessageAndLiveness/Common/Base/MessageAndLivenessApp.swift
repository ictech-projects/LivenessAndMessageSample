//
//  MessageAndLivenessApp.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 21/09/26.
//

import IQKeyboardManagerSwift
import SwiftUI
#if DEBUG
import netfox
#endif

@main
struct MessageAndLivenessApp: App {

	@UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
	@StateObject private var session = SessionStore()

	init() {
		tabBarAdjustment()
	}

	var body: some Scene {
		WindowGroup {
			RootView()
				.environmentObject(session)
		}
	}
}

extension MessageAndLivenessApp {

	private func tabBarAdjustment() {
		let appearance = UITabBarAppearance()

		appearance.configureWithOpaqueBackground()
		appearance.shadowColor = .clear
		appearance.shadowImage = UIImage()

		let normalFont = UIFont.baseStyle(size: 12, weight: .medium)
		let selectedFont = UIFont.baseStyle(size: 12, weight: .bold)

		appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
			.font: normalFont,
			.foregroundColor: UIColor(resource: .neutral90),
		]

		appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
			.font: selectedFont,
			.foregroundColor: UIColor(resource: .neutral90)
		]

		UITabBar.appearance().standardAppearance = appearance
		UITabBar.appearance().scrollEdgeAppearance = appearance
	}
}

final class AppDelegate: NSObject, UIApplicationDelegate {

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		FontRegistrar.registerAll()

		IQKeyboardManager.shared.isEnabled = true
		IQKeyboardManager.shared.resignOnTouchOutside = true

		#if DEBUG
		// Logs every URLSession request (incl. the BirchLabs API via URLSession.shared).
		// Shake the device/simulator (⌃⌘Z) to open the netfox log viewer.
		NFX.sharedInstance().start()
		#endif

		return true
	}
}
