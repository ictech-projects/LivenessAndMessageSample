//
//  ContentDefaultRemoteDataSource.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 03/02/26.
//

import Foundation
import Moya

final class ContentDefaultRemoteDataSource: ContentRemoteDataSource {
	private let provider: MoyaProvider<ContentTargetType>
	
	init(provider: MoyaProvider<ContentTargetType> = .defaultProvider()) {
		self.provider = provider
	}
	
	func base() async throws -> GeneralResponse<EmptyData> {
		try await self.provider.request(.base, model: GeneralResponse<EmptyData>.self)
	}
}
