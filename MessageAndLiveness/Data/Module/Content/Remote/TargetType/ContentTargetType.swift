//
//  ContentTargetType.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 02/02/26.
//

import Alamofire
import Foundation
import Moya

enum ContentTargetType {
	case base
}

extension ContentTargetType: BaseTargetType, AccessTokenAuthorizable {
	var authorizationType: AuthorizationType? {
		switch self {
		case .base:
			return .bearer
		}
	}
	var headers: [String: String]? {
		switch self {
		case .base:
			return [:]
		}
	}
	
	var parameterEncoding: Moya.ParameterEncoding {
		switch self {
		case .base:
			return URLEncoding.default
		}
	}
	
	var task: Task {
		return .requestParameters(parameters: parameters, encoding: parameterEncoding)
	}
	
	var parameters: [String: Any] {
		switch self {
		case .base:
			return [:]
		}
	}
	
	var path: String {
		switch self {
		case .base:
			return "/base"
		}
	}
	
	var sampleData: Data {
		switch self {
		case .base:
			return Data()
		}
	}
	
	var method: Moya.Method {
		switch self {
		case .base:
			return .get
		}
	}
}
