//
//  CountrySelectionModalSheetView.swift
// MessageAndLiveness
//
//  Created by Arifin Firdaus on 06/01/26.
//

import SwiftUI

struct CountrySelectionModalSheetView: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject var viewModel: CountrySelectionModalSheetViewModel
	@State private var searchText = ""
	
	private var filteredCountries: [Entity.Response.Country] {
		let raw = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
		if raw.isEmpty { return viewModel.countries }
		
		let isNumeric = raw.allSatisfy { $0.isNumber }
		let hasPlus = raw.contains("+")
		
		if hasPlus {
			return viewModel.countries.filter { country in
				guard let code = country.dialCode else { return false }
				return code.contains(raw)
			}
		}
		
		if isNumeric {
			return viewModel.countries.filter { country in
				let code = (country.dialCode ?? "").replacing("+", with: "")
				return code.contains(raw)
			}
		}

		return viewModel.countries.filter { country in
			(country.name ?? "").localizedStandardContains(raw)
		}
	}
	
	private var defaultCountry: Entity.Response.Country? {
		let defaultPhoneCode = "+61"
		return viewModel.countries.first { $0.dialCode == defaultPhoneCode }
	}
	
	var body: some View {
		NavigationStack {
			VStack {
				switch viewModel.viewState {
				case .initial, .loading:
					ProgressView()
				case .loaded:
					VStack(alignment: .leading) {
						Text("Suggested")
							.font(.baseStyle(size: 17, weight: .bold))
							.foregroundStyle(.neutral100)
							.padding(.vertical, 16)
						CountryRow(country: defaultCountry) {
							if let defaultCountry {
								viewModel.didSelectCountry(defaultCountry)
							}
							dismiss()
						}
						Text("Alphabetical")
							.font(.baseStyle(size: 17, weight: .bold))
							.foregroundStyle(.neutral100)
							.padding(.vertical, 16)
					}
					.padding(.horizontal, 16)
					
					if filteredCountries.isEmpty {
						Spacer()
						Text("No country found")
							.font(.baseStyle(size: 24, weight: .regular))
						Spacer()
					} else {
						List {
							ForEach(filteredCountries, id: \.self) { country in
								CountryRow(country: country) {
									viewModel.didSelectCountry(country)
									dismiss()
								}
								.listRowSeparator(.hidden)
							}
						}
					}
				case .error:
					EmptyView()
				}
			}
			.listStyle(.plain)
			.searchable(text: $searchText, prompt: "Search for a country")
			.navigationTitle("Select Country")
			.navigationBarTitleDisplayMode(.inline)
			.withCustomToolBar(
				backButton: (Image(systemName: "xmark"), { dismiss() }),
				background: (.visible, Color.neutral30),
				centerContent: (isShowLogo: false, title: Text("Select Country"))
			)
		}
		.preferredColorScheme(.light)
		.task {
			await viewModel.onLoad()
		}
	}
}

#Preview {
	CountrySelectionModalSheetView(
		viewModel: CountrySelectionModalSheetViewModel(
			delegate: PreviewCountrySelectionDelegate()
		)
	)
	
}

final class PreviewCountrySelectionDelegate: CountrySelectionDelegate {
	func didSelectCountry(_ country: Entity.Response.Country) { }
}
