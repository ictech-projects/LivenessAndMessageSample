import Foundation

nonisolated enum KeychainKey {
	case temporaryToken
    case accessToken
	case refreshToken
	case FCMToken
}

extension KeychainKey {
	nonisolated var key: String {
		switch self {
		case .temporaryToken:
			return "messageandliveness.auth.temporary_token"
		case .accessToken:
			return "messageandliveness.auth.access_token"
		case .refreshToken:
			return "messageandliveness.auth.refresh_token"
		case .FCMToken:
			return "messageandliveness.firebase.fcm_token"
		}
	}
}
