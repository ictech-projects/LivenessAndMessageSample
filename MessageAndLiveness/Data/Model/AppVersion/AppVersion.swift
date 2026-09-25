//
//  AppVersion.swift
// MessageAndLiveness
//
//  Created by Arifin Firdaus on 10/02/26.
//

enum AppVersion {
	enum Request {}
	enum Response {}
}

extension AppVersion.Request { }

extension AppVersion.Response {
	
	struct AppVersionStatus: Codable, Equatable, Hashable {
		let title: String?
		let message: String?
		let iosVersion: Int?
		let forceIOS: Bool?
		
		enum CodingKeys: String, CodingKey {
			case title
			case message
			case iosVersion = "ios_version"
			case forceIOS = "force_ios"
		}
	}
}
