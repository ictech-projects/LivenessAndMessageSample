//
//  EnvironmentConfiguration.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 22/09/25.
//

import Foundation

final class Configuration: Sendable {
	
	static let shared = Configuration()
	
	func environment() -> BaseEnvironment {
		if let configuration = Bundle.main.object(forInfoDictionaryKey: "Configuration") as? String {
			if configuration.range(of: "Development") != nil {
				return BaseEnvironment.development
			}
		}
		
		return BaseEnvironment.production
	}
}
