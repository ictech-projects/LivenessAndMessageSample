import Foundation

enum BaseEnvironment: String {
	case production = "Production"
	case development = "Development"
	
	var baseURL: String {
		switch self {
		case .production:
			"production url"
		case .development:
			"https://projectname.itmanage.com.au/api"
		}
	}
}
