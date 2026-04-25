import Logging
import SwiftData
import SwiftUI

private let appBootstrapLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.appBootstrap)

private func ensureApplicationSupportDirectoryExists() {
    guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}

@main
@MainActor
struct LiShuApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let sharedModelContainer: ModelContainer
    @State private var settings = AppSettings.shared
    @State private var showSplash = true
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var debugOverrideManager = DebugOverrideManager.shared
    @Environment(\.scenePhase) private var scenePhase

    private var resolvedColorScheme: ColorScheme? {
        switch settings.colorScheme {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    init() {
        UserDefaults.standard.set(["zh-Hans"], forKey: "AppleLanguages")

        if CommandLine.arguments.contains("--reset-onboarding") {
            AppSettings.shared.hasSeenOnboarding = false
        } else if CommandLine.arguments.contains(PulseDiagnostics.Constants.skipOnboardingArgument) {
            AppSettings.shared.hasSeenOnboarding = true
        } else if CommandLine.arguments.contains("--uitesting") {
            AppSettings.shared.hasSeenOnboarding = true
            AppSettings.shared.hasSeenGuideTour = true
            AppSettings.shared.hasSeenSuiLiGuide = true
        }

        let schema = Schema([
            Contact.self,
            Record.self,
            Event.self,
            RecordPhoto.self,
        ])

        let icloudEnabled = AppSettings.shared.icloudSyncEnabled
        let snapshotScreenshot = DemoDataSeeding.isFastlaneSnapshotMode
        appBootstrapLogger.notice("Initializing application", metadata: [
            "step": .string("bootstrap"),
            "result": .string(snapshotScreenshot ? "in_memory_demo" : (icloudEnabled ? "icloud" : "local")),
        ])

        ensureApplicationSupportDirectoryExists()

        do {
            let config = if snapshotScreenshot {
                ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )
            } else if icloudEnabled {
                ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .private("iCloud.com.finefine.LiShu")
                )
            } else {
                ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                )
            }
            sharedModelContainer = try ModelContainer(for: schema, configurations: [config])
            if snapshotScreenshot {
                DemoDataSeeding.insertSampleData(context: sharedModelContainer.mainContext, attachDemoMedia: true)
                appBootstrapLogger.info("Inserted demo data", metadata: ["step": .string("demo_seed")])
            }
            RecordTypeStorageNormalizer.runMigrationIfNeeded(context: sharedModelContainer.mainContext)
            EventHostModeNormalizer.run(context: sharedModelContainer.mainContext)
        } catch {
            appBootstrapLogger.error("Failed to create model container", metadata: [
                "step": .string("bootstrap"),
                "error": .string(error.localizedDescription),
            ])
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                } else if !settings.hasSeenOnboarding {
                    OnboardingView()
                        .transition(.opacity)
                } else {
                    MainTabView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showSplash)
            .animation(.easeInOut(duration: 0.4), value: settings.hasSeenOnboarding)
            .preferredColorScheme(resolvedColorScheme)
            .onAppear {
                InteractionLogger.screenView("app.splash")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showSplash = false
                }
            }
            .onChange(of: showSplash) { _, newValue in
                guard !newValue else { return }
                InteractionLogger.screenView(settings.hasSeenOnboarding ? "app.main" : "app.onboarding")
            }
            .onChange(of: settings.hasSeenOnboarding) { _, newValue in
                guard !showSplash else { return }
                InteractionLogger.screenView(newValue ? "app.main" : "app.onboarding")
            }
            .task {
                appBootstrapLogger.notice("Starting application tasks", metadata: ["step": .string("startup_tasks")])
                await subscriptionManager.loadProducts()
                await subscriptionManager.checkEntitlements()
                if settings.notificationEnabled {
                    let context = sharedModelContainer.mainContext
                    appBootstrapLogger.info("Rescheduling notifications on startup", metadata: [
                        "step": .string("startup_tasks"),
                        "result": .string("notification_reschedule"),
                    ])
                    NotificationManager.shared.rescheduleAll(context: context)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                appBootstrapLogger.info("Scene phase changed", metadata: [
                    "step": .string("scene_phase"),
                    "result": .string(String(describing: newPhase)),
                ])
                if newPhase == .active {
                    Task {
                        await subscriptionManager.checkEntitlements()
                    }
                }
            }
            .environment(\.locale, Locale(identifier: "zh-Hans"))
            .environment(settings)
            .environment(subscriptionManager)
            .environment(debugOverrideManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
