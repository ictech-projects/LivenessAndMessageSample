//
//  AppVersionDefaultRemoteDataSource.swift
// MessageAndLiveness
//
//  Created by Arifin Firdaus on 10/02/26.
//

import Moya

struct AppVersionDefaultRemoteDataSource: AppVersionRemoteDataSource {
	
	private let provider: MoyaProvider<AppVersionTargetType>
	
	init(provider: MoyaProvider<AppVersionTargetType> = .defaultProvider()) {
		self.provider = provider
	}
	
	func getAppVersionStatus() async throws -> GeneralResponse<AppVersion.Response.AppVersionStatus> {
		try await provider.request(
			.getAppVersionStatus,
			model: GeneralResponse<AppVersion.Response.AppVersionStatus>.self
		)
	}
}
