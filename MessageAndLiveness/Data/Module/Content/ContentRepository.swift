//
//  ContentRepository.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 03/02/26.
//

import Foundation

protocol ContentRepository {
	func base() async throws -> RequestState<GeneralResponse<EmptyData>>
}
