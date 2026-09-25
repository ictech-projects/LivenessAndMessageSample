//
//  GeneralResponse.swift
// MessageAndLiveness
//
//  Created by Ewide Dev 5 on 10/12/25.
//

import Foundation

struct GeneralResponse<T: Codable>: Codable {
	let success: Bool?
	let statusCode: Int?
	let message: String?
	let data: T?
	
	enum CodingKeys: String, CodingKey {
		case success
		case statusCode = "status_code"
		case message
		case data
	}
}
