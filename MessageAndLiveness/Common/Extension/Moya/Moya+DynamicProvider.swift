//
//  Moya+DynamicProvider.swift
// MessageAndLiveness
//
//  Created by Arifin Firdaus on 12/12/25.
//

import Foundation
import Moya

extension MoyaProvider {
	static func dynamicProvider() -> MoyaProvider {
#if DEBUG
		return MoyaProvider(plugins: [NetworkLoggerPlugin(), DynamicTokenPlugin()])
#else
		return MoyaProvider(plugins: [DynamicTokenPlugin()])
#endif
	}
}

final class DynamicTokenPlugin: PluginType {
	
	func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
		guard
			let authTarget = target as? AccessTokenAuthorizable,
			let type = authTarget.authorizationType
		else {
			return request
		}

		let keychain = KeychainHelper.shared

		let token: String =
			switch type {
			case .bearer:
				keychain.getString(for: KeychainKey.accessToken.key).orEmpty()
			case .custom(let string):
				if string == CustomAuthorizationTokenKey.tempToken {
					keychain.getString(for: KeychainKey.temporaryToken.key).orEmpty()
				} else {
					""
				}
			default:
				""
			}
		var req = request
		req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		return req
	}
}

enum CustomAuthorizationTokenKey {
	/// use this for change password
	static let tempToken = "temp_token"
}
