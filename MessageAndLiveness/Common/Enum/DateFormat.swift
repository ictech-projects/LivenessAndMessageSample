import Foundation

enum DateFormat: String {
	case utc = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
	case notifUTC = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
	case slashddMMyyyy = "dd/MM/yyyy"
	case dayOnly = "dd"
	case dayText = "EEE"
	case HHmmss = "HH:mm:ss"
	case HHmm = "HH:mm"
	case HHmma = "hh:mm a"
	case yyyyMMdd = "yyyy-MM-dd"
	case MMMddyyyyEEEE = "MMM dd, yyyy - EEEE"
	case yyyyMMddHHmm = "yyyy-MM-dd HH:mm"
	case yyyyMMddHHmmss = "yyyy-MM-dd HH:mm:ss"
	case yyyyMM = "yyyy-MM"
}
