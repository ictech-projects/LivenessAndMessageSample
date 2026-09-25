//
//  Entity.swift
//
//  Created by Arifin Firdaus on 18/12/25.
//

import Foundation
import SwiftUI

enum Entity {
	enum Request {}
	enum Response {}
}

extension Entity.Request { }

extension Entity.Response {
	
	struct Country: Hashable, Equatable {
		let code: String?
		let name: String?
		let dialCode: String?
		let flagSVG: String?
		let flagPNG: String?
		let flagImage: UIImage?
	}
}
