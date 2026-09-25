//
//  CountrySelectionModalSheetViewModel.swift
// MessageAndLiveness
//
//  Created by Arifin Firdaus on 06/01/26.
//

import Combine
import Foundation

@MainActor
protocol CountrySelectionDelegate: AnyObject {
	func didSelectCountry(_ country: Entity.Response.Country)
}

@MainActor
final class CountrySelectionModalSheetViewModel: ObservableObject {
	enum ViewState {
		case initial
		case loading
		case loaded
		case error
	}
	
	@Published var viewState = ViewState.initial
	@Published var errorMessage: String?
	@Published var apiMessage: String?
	
	@Published var countries: [Entity.Response.Country] = []
	@Published var currentCountry: Entity.Response.Country?
	@Published var phoneNumber = ""
	
	private let entityRepository: any EntityRepository
	private let delegate: any CountrySelectionDelegate
	
	private var cancellables = Set<AnyCancellable>()
	
	init(
		entityRepository: some EntityRepository = EntityDefaultRepository(),
		delegate: some CountrySelectionDelegate
		
	) {
		self.entityRepository = entityRepository
		self.delegate = delegate
	}
	
	func onLoad() async {
		await loadCountries()
	}
	
	private func loadCountries() async {
		viewState = .loading
		
		countries = await entityRepository.getCountries()
		
		/// set default country to Australia based on phoneCode
		if self.currentCountry == nil {
			self.currentCountry = countries.first(where: { $0.dialCode == "+61" })
		}
		
		viewState = .loaded
	}
	
	func didSelectCountry(_ country: Entity.Response.Country) {
		currentCountry = country
		delegate.didSelectCountry(country)
	}
}

