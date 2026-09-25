//
//  EntityDefaultRepository.swift
//  MessageAndLiveness
//
//  Created by Arifin Firdaus on 09/02/26.
//

import Foundation

struct EntityDefaultRepository: EntityRepository {
	func getCountries() async -> [Entity.Response.Country] {
		let locale = Locale.current

		// ISO alpha-2 country codes only (drops continents/groupings).
		let codes: [String] = Locale.Region.isoRegions
			.map(\.identifier)
			.filter { $0.count == 2 }

		var countries: [Entity.Response.Country] = []
		countries.reserveCapacity(codes.count)

		for code in codes {
			guard let name = locale.localizedString(forRegionCode: code) else { continue }
			let flagURL = "https://flagcdn.com/w40/" + code.lowercased() + ".png"
			countries.append(
				Entity.Response.Country(
					code: code,
					name: name,
					dialCode: nil,
					flagSVG: nil,
					flagPNG: flagURL,
					flagImage: nil
				)
			)
		}

		return countries.sorted { ($0.name ?? "") < ($1.name ?? "") }
	}
}
