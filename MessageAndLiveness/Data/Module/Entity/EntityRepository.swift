//
//  EntityRepository.swift
//  MessageAndLiveness
//
//  Created by Arifin Firdaus on 09/02/26.
//

import Foundation

protocol EntityRepository {
	func getCountries() async -> [Entity.Response.Country]
}
