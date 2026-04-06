import Logging
import SwiftUI

private let debugOverrideLogger = PulseDiagnostics.makeLogger(label: "debug.overrides")

@Observable
@MainActor
final class DebugOverrideManager {
    static let shared = DebugOverrideManager()

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
        proAccessOverrideEnabled
    }

    func effectiveProAccessEnabled(hasEntitlement: Bool) -> Bool {
        hasEntitlement || proAccessOverrideEnabled
    }

    func overrideSourceDescription(hasEntitlement: Bool) -> String {
        if hasEntitlement {
            return "StoreKit"
        }
        if proAccessOverrideEnabled {
            return "本次启动临时覆盖"
        }
        return "未启用"
    }

    func resetSessionOverrides() {
        proAccessOverrideEnabled = false
    }
}
