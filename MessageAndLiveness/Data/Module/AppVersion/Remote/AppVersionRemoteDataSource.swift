//
//  AppVersionRemoteDataSource.swift
// MessageAndLiveness
//
//  Created by Arifin Firdaus on 10/02/26.
//

import Foundation

protocol AppVersionRemoteDataSource {
	func getAppVersionStatus() async throws -> GeneralResponse<AppVersion.Response.AppVersionStatus>
}
