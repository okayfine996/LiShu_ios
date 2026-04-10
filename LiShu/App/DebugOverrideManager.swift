import Logging
import SwiftUI

private let debugOverrideLogger = PulseDiagnostics.makeLogger(label: "debug.overrides")

enum ProAccessSource: Equatable {
    case storeKit
    case testFlight
    case sessionOverride
    case none
}

@Observable
@MainActor
final class DebugOverrideManager {
    static let shared = DebugOverrideManager()

    private(set) var testFlightAutoProEnabled = false {
        didSet {
            guard oldValue != testFlightAutoProEnabled else { return }
            debugOverrideLogger.notice("Updated build override", metadata: [
                "target": .string("testflight_pro_access"),
                "result": .string(testFlightAutoProEnabled ? "enabled" : "disabled"),
            ])
        }
    }

    var proAccessOverrideEnabled = false {
        didSet {
            guard oldValue != proAccessOverrideEnabled else { return }
            debugOverrideLogger.notice("Updated session override", metadata: [
                "target": .string("pro_access"),
                "result": .string(proAccessOverrideEnabled ? "enabled" : "disabled"),
            ])
        }
    }

    var hasActiveOverrides: Bool {
        testFlightAutoProEnabled || proAccessOverrideEnabled
    }

    func effectiveProAccessEnabled(hasEntitlement: Bool) -> Bool {
        hasEntitlement || testFlightAutoProEnabled || proAccessOverrideEnabled
    }

    func effectiveAccessSource(hasEntitlement: Bool) -> ProAccessSource {
        if hasEntitlement {
            return .storeKit
        }
        if testFlightAutoProEnabled {
            return .testFlight
        }
        if proAccessOverrideEnabled {
            return .sessionOverride
        }
        return .none
    }

    func overrideSourceDescription(hasEntitlement: Bool) -> String {
        switch effectiveAccessSource(hasEntitlement: hasEntitlement) {
        case .storeKit:
            "StoreKit"
        case .testFlight:
            String(localized: "pro.override.source.testflight")
        case .sessionOverride:
            String(localized: "pro.override.source.session")
        case .none:
            String(localized: "pro.override.source.none")
        }
    }

    func configureBuildOverrides(isTestFlightBuild: Bool) {
        testFlightAutoProEnabled = isTestFlightBuild
    }

    func resetSessionOverrides() {
        proAccessOverrideEnabled = false
    }
}
