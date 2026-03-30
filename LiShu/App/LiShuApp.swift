import SwiftUI
import SwiftData

private func ensureApplicationSupportDirectoryExists() {
    guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}

@main
struct LiShuApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let sharedModelContainer: ModelContainer
    @State private var settings = AppSettings.shared
    @State private var showSplash = true
    @State private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.scenePhase) private var scenePhase

    private var resolvedColorScheme: ColorScheme? {
        switch settings.colorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    init() {
        UserDefaults.standard.set(["zh-Hans"], forKey: "AppleLanguages")

        if CommandLine.arguments.contains("--reset-onboarding") {
            AppSettings.shared.hasSeenOnboarding = false
        } else if CommandLine.arguments.contains("--uitesting") {
            AppSettings.shared.hasSeenOnboarding = true
        }

        let schema = Schema([
            Contact.self,
            Record.self,
            Event.self,
            RecordPhoto.self,
            CustomFestival.self,
            FestivalReminderPreference.self,
        ])

        let icloudEnabled = AppSettings.shared.icloudSyncEnabled

        ensureApplicationSupportDirectoryExists()

        do {
            let config: ModelConfiguration
            if icloudEnabled {
                config = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .private("iCloud.com.finefine.LiShu")
                )
            } else {
                config = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                )
            }
            sharedModelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showSplash = false
                }
            }
            .task {
                await subscriptionManager.loadProducts()
                await subscriptionManager.checkEntitlements()
                if settings.notificationEnabled {
                    let context = sharedModelContainer.mainContext
                    NotificationManager.shared.rescheduleAll(context: context)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await subscriptionManager.checkEntitlements()
                    }
                }
            }
            .environment(\.locale, Locale(identifier: "zh-Hans"))
            .environment(settings)
            .environment(subscriptionManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
