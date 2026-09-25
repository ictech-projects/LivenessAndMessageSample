//
//  ContentRemoteDataSource.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 03/02/26.
//

import Foundation

protocol ContentRemoteDataSource {
	func base() async throws -> GeneralResponse<EmptyData>
}
