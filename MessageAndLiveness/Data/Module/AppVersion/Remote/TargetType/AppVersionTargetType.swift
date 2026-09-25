//
//  AppVersionTargetType.swift
// MessageAndLiveness
//
//  Created by Arifin Firdaus on 10/02/26.
//

import Foundation
import Moya
import Alamofire

enum AppVersionTargetType {
	case getAppVersionStatus
}

extension AppVersionTargetType: BaseTargetType, AccessTokenAuthorizable {
	
	var authorizationType: AuthorizationType? {
		.bearer
	}
	
	var headers: [String: String]? {
		switch self {
		case .getAppVersionStatus:
			[
				"Accept": "application/json"
			]
		}
	}
	
	var method: Moya.Method {
		.get
	}
	
	var parameterEncoding: Moya.ParameterEncoding {
		switch self {
		case .getAppVersionStatus:
			return URLEncoding.default
		}
	}
	
	var task: Task {
		return .requestParameters(parameters: parameters, encoding: parameterEncoding)
	}
	
	var parameters: [String: Any] {
		switch self {
		case .getAppVersionStatus:
			return [:]
		}
	}
	
	var path: String {
		switch self {
		case .getAppVersionStatus:
			return "/app-version"
		}
	}
	
	var sampleData: Data {
		let response = GeneralResponse(
			success: true,
			statusCode: 200,
			message: "App Version Status fetched!",
			data: AppVersion.Response.AppVersionStatus(
				title: "\"Update Your App",
				message: "Please update to the latest version to continue.",
				iosVersion: 10,
				forceIOS: false
			)
		)
		return response.toJSONData()
	}
}
