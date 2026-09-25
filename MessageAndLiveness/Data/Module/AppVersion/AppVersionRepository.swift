//
//  AppVersionRepository.swift
// MessageAndLiveness
//
//  Created by Arifin Firdaus on 10/02/26.
//

protocol AppVersionRepository {
	func getAppVersionStatus() async throws -> RequestState<GeneralResponse<AppVersion.Response.AppVersionStatus>>
}
