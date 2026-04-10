import Foundation

enum AppBuildInfo {
    static var commitHash: String {
        let info = Bundle.main.infoDictionary
        if let hash = info?["LiShuGitCommit"] as? String, !hash.isEmpty {
            return hash
        }
        return "unknown"
    }

    static var isTestFlightBuild: Bool {
        isTestFlightBuild(
            appStoreReceiptURL: Bundle.main.appStoreReceiptURL,
            isSimulator: isSimulator,
            isPreview: isRunningInPreview
        )
    }

    static func isTestFlightBuild(
        appStoreReceiptURL: URL?,
        isSimulator: Bool,
        isPreview: Bool
    ) -> Bool {
        guard !isSimulator, !isPreview else { return false }
        return appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    private static var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private static var isSimulator: Bool {
        #if targetEnvironment(simulator)
            true
        #else
            false
        #endif
    }
}
