import Foundation
import Logging
import Pulse
import PulseLogHandler
import SwiftUI

/// Release 可用的文本诊断：静默写入 Pulse 存储、LRU 上限；控制台由「关于」页暗门唤起。
enum PulseDiagnostics {
    nonisolated enum Constants {
        static let storeSizeLimit: Int64 = 30 * 1_000_000
        static let disabledEnvironmentKey = "PULSE_DISABLED"
        static let uiTestingArgument = "--uitesting"
        static let skipOnboardingArgument = "--skip-onboarding"
        static let xCTestConfigurationFilePathKey = "XCTestConfigurationFilePath"
    }

    private nonisolated static let lock = NSLock()
    private nonisolated(unsafe) static var didConfigure = false
    private(set) nonisolated(unsafe) static var didBootstrapLoggingSystem = false

    /// 是否启用自动拦截与存储。关闭方式：`PULSE_DISABLED=1` 环境变量，或 UI 测试 `--uitesting`。
    nonisolated static var isMonitoringEnabled: Bool {
        monitoringEnabled(arguments: CommandLine.arguments, environment: ProcessInfo.processInfo.environment)
    }

    /// 是否允许通过暗门打开 Pulse 控制台（UI 测试时关闭，避免误触干扰自动化）。
    nonisolated static var isHiddenConsoleAvailable: Bool {
        hiddenConsoleAvailable(arguments: CommandLine.arguments, environment: ProcessInfo.processInfo.environment)
    }

    /// 暗门唤起后的支持说明。分享动作仍由 PulseUI 的原生导出能力负责。
    nonisolated static let supportSummary = "诊断面板会本地保存应用日志，便于排查启动、交互、订阅、导入导出等流程问题。日志不会自动上传，只有在你手动分享时才会导出。"

    nonisolated static func makeLogger(label: String) -> Logger {
        configureIfNeeded()
        return Logger(label: label)
    }

    /// 在应用启动早期调用一次；配置 `LoggerStore` 上限并接入统一文本日志。
    nonisolated static func configureIfNeeded(
        arguments: [String] = CommandLine.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        guard !didConfigure else { return }
        lock.lock()
        defer { lock.unlock() }
        guard !didConfigure else { return }
        didConfigure = true
        guard monitoringEnabled(arguments: arguments, environment: environment) else { return }

        installSharedLoggerStore()
        bootstrapLoggingSystemIfNeeded()
        let logger = Logger(label: "diagnostics.pulse")
        logger.info("Pulse diagnostics initialized", metadata: [
            "store_size_limit_mb": .stringConvertible(Constants.storeSizeLimit / 1_000_000),
        ])
    }

    nonisolated static func monitoringEnabled(arguments: [String], environment: [String: String]) -> Bool {
        if arguments.contains(Constants.uiTestingArgument) { return false }
        if environment[Constants.disabledEnvironmentKey] == "1" { return false }
        if environment[Constants.xCTestConfigurationFilePathKey] != nil { return false }
        return true
    }

    nonisolated static func hiddenConsoleAvailable(arguments: [String], environment: [String: String]) -> Bool {
        monitoringEnabled(arguments: arguments, environment: environment)
    }

    nonisolated static func makeLoggerStoreConfiguration(isDebugBuild _: Bool = defaultDebugBuildValue()) -> LoggerStore.Configuration {
        LoggerStore.Configuration(sizeLimit: Constants.storeSizeLimit)
    }

    nonisolated static func installSharedLoggerStore() {
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

    nonisolated static func bootstrapLoggingSystemIfNeeded() {
        guard !didBootstrapLoggingSystem else { return }
        LoggingSystem.bootstrap { label in
            PersistentLogHandler(label: label, store: LoggerStore.shared)
        }
        didBootstrapLoggingSystem = true
    }

    /// 与 Pulse 内部默认路径一致（`Library/Logs/com.github.kean.logger/current.pulse`），避免重复占用空间。
    nonisolated static func pulseStorePackageURL() -> URL {
        guard let libraryRoot = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("current.pulse")
        }
        let base = libraryRoot
            .appendingPathComponent("Logs/com.github.kean.logger", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("current.pulse", isDirectory: true)
    }

    nonisolated static func defaultDebugBuildValue() -> Bool {
        #if DEBUG
            true
        #else
            false
        #endif
    }

    #if DEBUG
        nonisolated static func resetForTesting() {
            lock.lock()
            didConfigure = false
            lock.unlock()
        }
    #endif
}

nonisolated enum AppLogLabel {
    static let appBootstrap = "app.bootstrap"
    static let uiInteraction = "ui.interaction"
    static let dataRecord = "data.record"
    static let dataMutation = "data.mutation"
    static let dataQuery = "data.query"
    static let dataOCR = "data.ocr"
    static let settings = "settings.app"
    static let notifications = "notifications.manager"
    static let export = "storage.export"
    static let importFlow = "storage.import"
    static let ocr = "ocr.pipeline"
    static let ai = "ai.analysis"
    static let contactsViewModel = "contacts.viewmodel"
    static let eventsViewModel = "events.viewmodel"
    static let recordsViewModel = "records.viewmodel"
    static let statsViewModel = "stats.viewmodel"
}

nonisolated enum UILogEventType: String {
    case screenView = "screen_view"
    case tap
    case toggle
    case tabSwitch = "tab_switch"
    case navigation
    case sheetPresent = "sheet_present"
    case sheetDismiss = "sheet_dismiss"
    case alertPresent = "alert_present"
    case alertAction = "alert_action"
    case contextMenuAction = "context_menu_action"
    case saveSubmit = "save_submit"
    case deleteConfirm = "delete_confirm"
}

nonisolated enum UILogPresentation: String {
    case push
    case sheet
    case fullScreen = "full_screen"
    case alert
    case tab
}

nonisolated enum UILogAction: String {
    case tap
    case open
    case save
    case delete
    case toggle
    case select
    case dismiss
    case present
    case submit
}

nonisolated enum InteractionLogger {
    private static let logger = PulseDiagnostics.makeLogger(label: AppLogLabel.uiInteraction)

    static func screenView(_ screen: String, metadata: [String: String] = [:]) {
        log(
            eventType: .screenView,
            screen: screen,
            target: screen,
            action: .open,
            metadata: metadata
        )
    }

    static func tap(
        screen: String,
        target: String,
        route: String? = nil,
        presentation: UILogPresentation? = nil,
        metadata: [String: String] = [:]
    ) {
        log(
            eventType: .tap,
            screen: screen,
            target: target,
            action: .tap,
            route: route,
            presentation: presentation,
            metadata: metadata
        )
    }

    static func toggle(screen: String, target: String, isOn: Bool, metadata: [String: String] = [:]) {
        var enrichedMetadata = metadata
        enrichedMetadata["result"] = isOn ? "on" : "off"
        log(
            eventType: .toggle,
            screen: screen,
            target: target,
            action: .toggle,
            metadata: enrichedMetadata
        )
    }

    static func tabSwitch(screen: String, target: String, route: String) {
        log(
            eventType: .tabSwitch,
            screen: screen,
            target: target,
            action: .select,
            route: route,
            presentation: .tab
        )
    }

    static func navigation(
        screen: String,
        target: String,
        route: String,
        presentation: UILogPresentation = .push,
        metadata: [String: String] = [:]
    ) {
        log(
            eventType: .navigation,
            screen: screen,
            target: target,
            action: .open,
            route: route,
            presentation: presentation,
            metadata: metadata
        )
    }

    static func sheetPresentation(screen: String, route: String, isPresented: Bool) {
        log(
            eventType: isPresented ? .sheetPresent : .sheetDismiss,
            screen: screen,
            target: route,
            action: isPresented ? .present : .dismiss,
            route: route,
            presentation: .sheet
        )
    }

    static func fullScreenPresentation(screen: String, route: String, isPresented: Bool) {
        log(
            eventType: isPresented ? .sheetPresent : .sheetDismiss,
            screen: screen,
            target: route,
            action: isPresented ? .present : .dismiss,
            route: route,
            presentation: .fullScreen
        )
    }

    static func alertPresentation(screen: String, target: String, isPresented: Bool, metadata: [String: String] = [:]) {
        log(
            eventType: isPresented ? .alertPresent : .alertAction,
            screen: screen,
            target: target,
            action: isPresented ? .present : .dismiss,
            presentation: .alert,
            metadata: metadata
        )
    }

    static func alertAction(screen: String, target: String, action: UILogAction, result: String? = nil, reason: String? = nil) {
        var metadata: [String: String] = [:]
        metadata["result"] = result
        metadata["reason"] = reason
        log(
            eventType: .alertAction,
            screen: screen,
            target: target,
            action: action,
            presentation: .alert,
            metadata: metadata
        )
    }

    static func contextMenuAction(screen: String, target: String, action: UILogAction, metadata: [String: String] = [:]) {
        log(
            eventType: .contextMenuAction,
            screen: screen,
            target: target,
            action: action,
            metadata: metadata
        )
    }

    static func submit(
        screen: String,
        target: String,
        action: UILogAction,
        result: String? = nil,
        reason: String? = nil,
        metadata: [String: String] = [:]
    ) {
        var enrichedMetadata = metadata
        enrichedMetadata["result"] = result
        enrichedMetadata["reason"] = reason
        log(
            eventType: action == .delete ? .deleteConfirm : .saveSubmit,
            screen: screen,
            target: target,
            action: action,
            metadata: enrichedMetadata
        )
    }

    static func log(
        eventType: UILogEventType,
        screen: String,
        target: String,
        action: UILogAction,
        route: String? = nil,
        presentation: UILogPresentation? = nil,
        metadata: [String: String] = [:]
    ) {
        var payload: Logger.Metadata = [
            "event_type": .string(eventType.rawValue),
            "screen": .string(screen),
            "target": .string(target),
            "action": .string(action.rawValue),
        ]
        if let route {
            payload["route"] = .string(route)
        }
        if let presentation {
            payload["presentation"] = .string(presentation.rawValue)
        }
        for (key, value) in metadata where !value.isEmpty {
            payload[key] = .string(value)
        }
        logger.notice("UI interaction", metadata: payload)
    }
}

private struct ScreenViewLoggingModifier: ViewModifier {
    let screen: String
    let metadata: [String: String]

    func body(content: Content) -> some View {
        content.onAppear {
            InteractionLogger.screenView(screen, metadata: metadata)
        }
    }
}

extension View {
    func trackScreen(_ screen: String, metadata: [String: String] = [:]) -> some View {
        modifier(ScreenViewLoggingModifier(screen: screen, metadata: metadata))
    }
}
