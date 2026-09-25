enum PageSlugType: String {
	case aboutUs = "about-us"
	case tnc = "terms-and-conditions"
	case privacyPolicy = "privacy-policy"
}

extension PageSlugType {
	var title: String {
		switch self {
		case .aboutUs:
			return "About Us"
		case .tnc:
			return "Terms and Condition"
		case .privacyPolicy:
			return "Privacy Policy"
		}
	}
}

