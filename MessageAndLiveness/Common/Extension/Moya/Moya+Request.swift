//
//  Moya+Request.swift
//  HJK
//
//  Created by Ewide Dev 5 on 11/09/25.
//

import Moya
import Foundation

extension MoyaProvider {
	func requestAsync(_ target: Target) async throws -> Response {
		try await withCheckedThrowingContinuation { continuation in
			self.request(target) { result in
				switch result {
				case .success(let response):
					continuation.resume(returning: response)
				case .failure(let error):
					continuation.resume(throwing: error)
				}
			}
		}
	}
	
	func request<T: Codable>(
		_ target: Target,
		model: T.Type,
		with dateDecodeStrategy: DateFormat = .yyyyMMdd
	) async throws -> T {
		
		do {
			// 1. Request using async/await
			let response = try await self.requestAsync(target)
			
			// 2. Prepare decoder
			let decoder = JSONDecoder()
			let formatter = DateFormatter()
			formatter.dateFormat = dateDecodeStrategy.rawValue
			decoder.dateDecodingStrategy = .formatted(formatter)
			
			// 3. Check status code
			let statusCode = response.statusCode
			
			if (200...399).contains(statusCode) {
				// Success → decode to model
				return try decoder.decode(T.self, from: response.data)
			} else {
				// Failed → decode ErrorResponse
				let errorResponse = try decoder.decode(ErrorResponse.self, from: response.data)
				throw errorResponse
			}
			
		} catch let error as ErrorResponse {
			throw error
		} catch let error as MoyaError {
			// Convert MoyaError → ErrorResponse
			throw ErrorResponse(
				success: false,
				statusCode: -1,
				message: error.errorDescription ?? "Unknown error",
				errors: nil
			)
		} catch {
			// Other errors
			throw ErrorResponse(
				success: false,
				statusCode: -1,
				message: error.localizedDescription,
				errors: nil
			)
		}
	}
}
