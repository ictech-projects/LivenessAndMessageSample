//
//  AppVersionDefaultRepository.swift
// MessageAndLiveness
//
//  Created by Arifin Firdaus on 10/02/26.
//

import Foundation

struct AppVersionDefaultRepository: AppVersionRepository {
	
	private let remote: any AppVersionRemoteDataSource
	
	init(remote: some AppVersionRemoteDataSource = AppVersionDefaultRemoteDataSource()) {
		self.remote = remote
	}
	
	func getAppVersionStatus() async throws -> RequestState<GeneralResponse<AppVersion.Response.AppVersionStatus>> {
		await execute { try await remote.getAppVersionStatus() }
	}
}
