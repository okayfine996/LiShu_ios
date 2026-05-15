import Foundation
import Observation

// MARK: - DeepLinkCoordinator

@Observable
@MainActor
final class DeepLinkCoordinator {
    var pending: DeepLink?
}
