import Foundation
import Logging
import Pulse
import PulseLogHandler

#if DEBUG
import PulseProxy
#endif

/// Release 可用的网络诊断：静默写入 Pulse 存储、敏感字段脱敏、LRU 上限；控制台由「关于」页暗门唤起。
///
/// 说明：
/// - 生产构建默认只启用本地存储与安全分享能力，不启用 PulseProxy。
/// - PulseProxy 依赖 swizzling / 私有 API，仅允许在 DEBUG 或显式内部调试环境中开启。
/// - 目前项目代码中未发现自建 `URLSession` 网络层；因此 Pulse 更适合作为诊断闭环基础设施，
///   后续若新增 App 自有网络请求，应优先改为 `URLSessionProxy` 或手动注入 `NetworkLogger`。
enum PulseDiagnostics {
    enum Constants {
        static let storeSizeLimit: Int64 = 30 * 1_000_000
        static let releaseResponseBodySizeLimit = 128 * 1024
        static let disabledEnvironmentKey = "PULSE_DISABLED"
        static let unsafeProxyEnvironmentKey = "PULSE_ENABLE_UNSAFE_PROXY"
        static let uiTestingArgument = "--uitesting"
        static let skipOnboardingArgument = "--skip-onboarding"

        static let excludedHosts: Set<String> = [
            "*.apple.com",
            "*.icloud.com",
            "*.mzstatic.com",
            "*.itunes.apple.com",
            "*.appstore.com"
        ]

        static let sensitiveHeaders: Set<String> = [
            "Authorization",
            "Cookie",
            "Set-Cookie",
            "Proxy-Authorization",
            "X-API-Key",
            "X-Auth-Token",
            "X-Csrf-Token",
            "X-*"
        ]

        static let sensitiveQueryItems: Set<String> = [
            "token",
            "access_token",
            "refresh_token",
            "key",
            "auth",
            "code",
            "password"
        ]

        static let sensitiveDataFields: Set<String> = [
            "token",
            "access_token",
            "refresh_token",
            "authorization",
            "cookie",
            "password",
            "phone",
            "mobile",
            "email",
            "idCard",
            "id_card"
        ]
    }

    private static let lock = NSLock()
    private static var didConfigure = false
    private(set) static var didBootstrapLoggingSystem = false

    /// 是否启用自动拦截与存储。关闭方式：`PULSE_DISABLED=1` 环境变量，或 UI 测试 `--uitesting`。
    static var isMonitoringEnabled: Bool {
        monitoringEnabled(arguments: CommandLine.arguments, environment: ProcessInfo.processInfo.environment)
    }

    /// 是否允许通过暗门打开 Pulse 控制台（UI 测试时关闭，避免误触干扰自动化）。
    static var isHiddenConsoleAvailable: Bool {
        hiddenConsoleAvailable(arguments: CommandLine.arguments, environment: ProcessInfo.processInfo.environment)
    }

    /// 暗门唤起后的支持说明。分享动作仍由 PulseUI 的原生导出能力负责。
    static let supportSummary = "诊断面板会本地保存应用日志与网络日志，并在分享前自动隐藏常见敏感字段。当前网络采集主要覆盖应用自有 URLSession 请求；Apple 托管服务（如 StoreKit、CloudKit）可能不会完整显示。"

    /// 在应用启动早期调用一次；配置 `LoggerStore` 上限与 `NetworkLogger` 脱敏规则。
    static func configureIfNeeded(
        arguments: [String] = CommandLine.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        installUnsafeProxy: Bool = shouldInstallUnsafeProxy(environment: ProcessInfo.processInfo.environment)
    ) {
        lock.lock()
        defer { lock.unlock() }
        guard !didConfigure else { return }
        didConfigure = true
        guard monitoringEnabled(arguments: arguments, environment: environment) else { return }

        installSharedLoggerStore()
        bootstrapLoggingSystemIfNeeded()
        NetworkLogger.shared = NetworkLogger(
            store: LoggerStore.shared,
            configuration: makeNetworkLoggerConfiguration()
        )
        let logger = Logger(label: "diagnostics.pulse")
        logger.info("Pulse diagnostics initialized", metadata: [
            "store_size_limit_mb": .stringConvertible(Constants.storeSizeLimit / 1_000_000),
            "network_proxy": .stringConvertible(defaultNetworkProxyValue())
        ])

        #if DEBUG
        if defaultNetworkProxyValue() {
            NetworkLogger.enableProxy()
        }
        #else
        if installUnsafeProxy {
            assertionFailure("PulseProxy is unsupported in production and should only be enabled for internal validation builds.")
        }
        #endif
    }

    static func monitoringEnabled(arguments: [String], environment: [String: String]) -> Bool {
        if arguments.contains(Constants.uiTestingArgument) { return false }
        if environment[Constants.disabledEnvironmentKey] == "1" { return false }
        return true
    }

    static func hiddenConsoleAvailable(arguments: [String], environment: [String: String]) -> Bool {
        monitoringEnabled(arguments: arguments, environment: environment)
    }

    static func makeNetworkLoggerConfiguration() -> NetworkLogger.Configuration {
        var configuration = NetworkLogger.Configuration()
        configuration.excludedHosts = Constants.excludedHosts
        configuration.sensitiveHeaders = Constants.sensitiveHeaders
        configuration.sensitiveQueryItems = Constants.sensitiveQueryItems
        configuration.sensitiveDataFields = Constants.sensitiveDataFields
        return configuration
    }

    static func makeLoggerStoreConfiguration(isDebugBuild: Bool = defaultDebugBuildValue()) -> LoggerStore.Configuration {
        var configuration = LoggerStore.Configuration(sizeLimit: Constants.storeSizeLimit)
        if !isDebugBuild {
            configuration.responseBodySizeLimit = Constants.releaseResponseBodySizeLimit
        }
        return configuration
    }

    static func installSharedLoggerStore() {
        let storeURL = pulseStorePackageURL()
        do {
            let configuration = makeLoggerStoreConfiguration()
            let store = try LoggerStore(
                storeURL: storeURL,
                options: [.create, .sweep],
                configuration: configuration
            )
            LoggerStore.shared = store
        } catch {
            #if DEBUG
            assertionFailure("Pulse LoggerStore init failed: \(error)")
            #endif
        }
    }

    static func bootstrapLoggingSystemIfNeeded() {
        guard !didBootstrapLoggingSystem else { return }
        LoggingSystem.bootstrap { label in
            PersistentLogHandler(label: label, store: LoggerStore.shared)
        }
        didBootstrapLoggingSystem = true
    }

    /// 与 Pulse 内部默认路径一致（`Library/Logs/com.github.kean.logger/current.pulse`），避免重复占用空间。
    static func pulseStorePackageURL() -> URL {
        let base = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Logs/com.github.kean.logger", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("current.pulse", isDirectory: true)
    }

    static func shouldInstallUnsafeProxy(environment: [String: String]) -> Bool {
        #if DEBUG
        true
        #else
        environment[Constants.unsafeProxyEnvironmentKey] == "1"
        #endif
    }

    static func defaultDebugBuildValue() -> Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    static func defaultNetworkProxyValue() -> Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    #if DEBUG
    static func resetForTesting() {
        lock.lock()
        didConfigure = false
        lock.unlock()
    }
    #endif
}
