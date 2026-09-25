//
//  ContentDefaultRepository.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 03/02/26.
//

import Foundation

final class ContentDefaultRepository: ContentRepository {
	private let remote: ContentRemoteDataSource
	
	init(remote: ContentRemoteDataSource = ContentDefaultRemoteDataSource()) {
		self.remote = remote
	}
	
	func base() async throws -> RequestState<GeneralResponse<EmptyData>> {
		do {
			let result = try await remote.base()
			return .loaded(result)
		} catch let error as ErrorResponse {
			return .error(error)
		} catch {
			return .error(error)
		}
	}
}
