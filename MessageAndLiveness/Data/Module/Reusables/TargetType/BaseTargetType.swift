//
//  BaseTargetType.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 11/09/25.
//

import Alamofire
import Foundation
import Moya

protocol BaseTargetType: TargetType {
    var parameters: [String: Any] {
        get
    }
}

extension BaseTargetType {
    public var baseURL: URL {
		return URL(string: Configuration.shared.environment().baseURL) ?? (NSURL() as URL)
    }
    
    var parameterEncoding: Moya.ParameterEncoding {
        JSONEncoding.default
    }
    
    var task: Task {
        return .requestParameters(parameters: parameters, encoding: parameterEncoding)
    }
    
    public var headers: [String: String]? {
        return [:]
    }
}
