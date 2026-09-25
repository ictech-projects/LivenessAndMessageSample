import Foundation
import SwiftUI

enum AlertType {
    case error
    case success
    case locationNotSet
	case messageSend
	case passwordUpdate
	case deleteAccount
	case deleteAccountSuccess
	case profileUpdated
	case removeConnectedDevice
	case logout

}

extension AlertType {
	var icon: Image {
		switch self {
		case .error:
			Image(.errorAlertIcon)
		case .success, .profileUpdated:
			Image(.successAlertIcon)
		case .locationNotSet:
			Image(.locationErrorAlertIcon)
		case .messageSend:
			Image(.sendMessageAlertIcon)
		case .passwordUpdate:
			Image(.updatePasswordSuccessAlertIcon)
		case .deleteAccount:
			Image(.deleteAccountAlertIcon)
		case .deleteAccountSuccess:
			Image(.sendMessageAlertIcon)
		case .removeConnectedDevice:
			Image(.removeAlertIcon)
		case .logout:
			Image(.logoutAlertIcon)
		}
	}
	
	var titleColor: Color {
		switch self {
		case .error, .deleteAccount, .removeConnectedDevice, .logout:
			Color.dangerMain
		case .success:
			Color.successMain
		case .passwordUpdate, .deleteAccountSuccess:
			Color.infoMain
		case .messageSend:
			Color.infoMain
		default:
			Color.neutral90
		}
	}
}
