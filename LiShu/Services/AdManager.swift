import Foundation
import GoogleMobileAds
import Logging

private let adLogger = PulseDiagnostics.makeLogger(label: "ads.manager")

@Observable
@MainActor
final class AdManager: NSObject {
    static let shared = AdManager()

    // MARK: - Ad Unit IDs

    #if DEBUG
        private let nativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"
    #else
        private let nativeAdUnitID = "ca-app-pub-9544808001963212/5215183715"
    #endif

    // MARK: - Ad Instances

    @ObservationIgnored private var adLoader: AdLoader?
    private(set) var nativeAd: NativeAd?

    // MARK: - 频控

    @ObservationIgnored private var lastNativeAdTime: Date = .distantPast
    @ObservationIgnored private let nativeAdCooldown: TimeInterval = 120
    @ObservationIgnored private var nativeAdShowCount = 0
    @ObservationIgnored private let maxNativeAdPerSession = 5

    // MARK: - 状态

    var showNativeAdOverlay = false
    @ObservationIgnored var onNativeAdDismissed: (() -> Void)?

    // MARK: - 初始化

    func configure() {
        adLogger.info("Initializing Google Mobile Ads SDK")
        MobileAds.shared.start { status in
            adLogger.info("AdMob SDK initialized", metadata: [
                "adapters": .string(
                    status.adapterStatusesByClassName.keys.joined(separator: ", ")
                ),
            ])
        }
        preloadNativeAd()
    }

    // MARK: - Pro 检查

    private var shouldShowAds: Bool {
        !SubscriptionManager.shared.effectiveIsPro()
    }

    // MARK: - 原生广告 (Native Ad)

    func preloadNativeAd() {
        guard shouldShowAds else { return }

        let loader = AdLoader(
            adUnitID: nativeAdUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: [NativeAdMediaAdLoaderOptions()]
        )
        loader.delegate = self
        loader.load(Request())
        adLoader = loader
        adLogger.info("Loading native ad")
    }

    /// 延迟后在主界面展示原生广告卡片。调用方应先 dismiss 编辑页，再调用此方法。
    /// 多次快速调用是安全的：第一次展示后 dismissNativeAd() 会清空 nativeAd，后续 Task 醒来检查不通过。
    func scheduleNativeAd() {
        guard canShowNativeAd, nativeAd != nil else { return }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            guard self.nativeAd != nil, self.canShowNativeAd else { return }
            self.lastNativeAdTime = Date()
            self.nativeAdShowCount += 1
            self.showNativeAdOverlay = true
            adLogger.info("Presenting native ad card", metadata: [
                "session_count": .stringConvertible(self.nativeAdShowCount),
            ])
        }
    }

    /// 关闭原生广告卡片，触发回调。
    func dismissNativeAd() {
        showNativeAdOverlay = false
        nativeAd = nil
        preloadNativeAd()
        onNativeAdDismissed?()
        onNativeAdDismissed = nil
    }

    private var canShowNativeAd: Bool {
        shouldShowAds
            && Date().timeIntervalSince(lastNativeAdTime) > nativeAdCooldown
            && nativeAdShowCount < maxNativeAdPerSession
    }
}

// MARK: - AdLoaderDelegate + NativeAdLoaderDelegate (原生广告)

extension AdManager: AdLoaderDelegate {
    nonisolated func adLoader(_: AdLoader, didFailToReceiveAdWithError error: Error) {
        Task { @MainActor in
            adLogger.warning("Native ad failed to load", metadata: [
                "error": .string(error.localizedDescription),
            ])
        }
    }
}

extension AdManager: NativeAdLoaderDelegate {
    nonisolated func adLoader(_: AdLoader, didReceive nativeAd: NativeAd) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.nativeAd = nativeAd
            adLogger.info("Native ad loaded successfully")
        }
    }
}
