import Foundation

enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var value: T? {
        if case let .loaded(v) = self { return v }
        return nil
    }

    var errorMessage: String? {
        if case let .error(msg) = self { return msg }
        return nil
    }
}
