//
//  CountryRow.swift
// MessageAndLiveness
//
//  Created by Arifin Firdaus on 06/01/26.
//

import SwiftUI
import SDWebImageSwiftUI

struct CountryRow: View {
	let country: Entity.Response.Country?
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			VStack {
				HStack {
					CountryFlagView(urlString: country?.flagPNG ?? "", flagImage: country?.flagImage)
					Text(country?.name ?? "")
						.font(.baseStyle(size: 17, weight: .regular))
						.foregroundStyle(.neutral90)
					Spacer()
					Text(country?.dialCode ?? "")
						.font(.baseStyle(size: 17, weight: .regular))
						.foregroundStyle(.neutral90)
				}
				.foregroundStyle(.brandPrimary)
				Divider()
			}
		}
	}
}

#Preview {
	CountryRow(
		country: Entity.Response.Country(
			code: "ID",
			name: "Indonesia",
			dialCode: "+62",
			flagSVG: "https://example.com/flags/id.svg",
			flagPNG: "https://example.com/flags/id.png",
			flagImage: nil
		),
		action: {
			print("Country tapped")
		}
	)
}
