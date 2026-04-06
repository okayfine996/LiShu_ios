import Foundation

enum AppBuildInfo {
    static var commitHash: String {
        let info = Bundle.main.infoDictionary
        if let hash = info?["LiShuGitCommit"] as? String, !hash.isEmpty {
            return hash
        }
        return "unknown"
    }
}
