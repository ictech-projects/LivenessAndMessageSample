//
//  Moya+Request.swift
// MessageAndLiveness
//
//  Created by Ewide Dev 5 on 11/09/25.
//

import Combine
import CombineMoya
import Foundation
import Moya

extension MoyaProvider {
	func request<T: Codable>(_ target: Target, model: T.Type, with dateDecodeStrategy: DateFormat = .yyyyMMdd) -> AnyPublisher<T, ErrorResponse> {
		self.requestPublisher(target)
			.mapError({ moyaError in
				return ErrorResponse(
					success: false,
					statusCode: -1,
					message: moyaError.errorDescription,
					errors: nil
				)
			})
			.flatMap({ (response) -> AnyPublisher<T, ErrorResponse> in
				let errorCode = response.statusCode
				let jsonDecoder = JSONDecoder()
				let formatter = DateFormatter()
				formatter.dateFormat = dateDecodeStrategy.rawValue
				jsonDecoder.dateDecodingStrategy = .formatted(formatter)
				
				do {
					if errorCode == 200 || errorCode == 201 {
						let model = try jsonDecoder.decode(model.self, from: response.data)
						return Just(model).setFailureType(to: ErrorResponse.self).eraseToAnyPublisher()
					} else {
						let errorResponse = try jsonDecoder.decode(ErrorResponse.self, from: response.data)
						return Fail(error: errorResponse).eraseToAnyPublisher()
					}
				} catch {
					print(error)
					let baseError = ErrorResponse(
						success: false,
						statusCode: -1,
						message: error.localizedDescription,
						errors: nil
					)
					
					return Fail(error: baseError).eraseToAnyPublisher()
				}
			})
			.eraseToAnyPublisher()
	}
}
