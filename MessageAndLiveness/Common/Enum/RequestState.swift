import Foundation

enum RequestState<T: Codable> {
	case idle
	case loading
	case refresh
	case expired
	case paginationLoading
	case loaded(T)
	case error(Error)
}

extension RequestState: Equatable {
	static func == (lhs: RequestState<T>, rhs: RequestState<T>) -> Bool {
		switch (lhs, rhs) {
		case (.idle, .idle):
			return true
		case (.loading, .loading):
			return true
		case (.refresh, .refresh):
			return true
		case (.loaded(let l), .loaded(let r)):
			return l.toJSONData() == r.toJSONData()
		case (.error, .error):
			return true
		case (.expired, .expired):
			return true
		case (.paginationLoading, .paginationLoading):
			return true
		default:
			return false
		}
	}
}
