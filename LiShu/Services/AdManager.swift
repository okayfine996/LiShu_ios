import Foundation
import GoogleMobileAds
import Logging
import UIKit

private let adLogger = PulseDiagnostics.makeLogger(label: "ads.manager")

@Observable
@MainActor
final class AdManager: NSObject {
    static let shared = AdManager()

    // MARK: - Ad Unit IDs

    #if DEBUG
        private let appOpenAdUnitID = "ca-app-pub-3940256099942544/5575463023"
        private let nativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"
    #else
        private let appOpenAdUnitID = "ca-app-pub-9544808001963212/2497136594"
        private let nativeAdUnitID = "ca-app-pub-9544808001963212/5215183715"
    #endif

    // MARK: - Ad Instances

    @ObservationIgnored private var appOpenAd: AppOpenAd?
    @ObservationIgnored private var adLoader: AdLoader?
    private(set) var nativeAd: NativeAd?

    // MARK: - 频控

    @ObservationIgnored private var lastNativeAdTime: Date = .distantPast
    @ObservationIgnored private let nativeAdCooldown: TimeInterval = 120
    @ObservationIgnored private var nativeAdShowCount = 0
    @ObservationIgnored private let maxNativeAdPerSession = 5

    // MARK: - 状态

    private(set) var isShowingAd = false
    var showNativeAdOverlay = false
    @ObservationIgnored var onNativeAdDismissed: (() -> Void)?
    @ObservationIgnored var onAppOpenAdDismissed: (() -> Void)?

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
        preloadAppOpenAd()
        preloadNativeAd()
    }

    // MARK: - Pro 检查

    private var shouldShowAds: Bool {
        !SubscriptionManager.shared.effectiveIsPro()
    }

    // MARK: - 开屏广告 (App Open Ad)

    func preloadAppOpenAd() {
        guard shouldShowAds else { return }

        AppOpenAd.load(
            with: appOpenAdUnitID,
            request: Request()
        ) { ad, error in
            if let error {
                adLogger.warning("App open ad failed to load", metadata: [
                    "error": .string(error.localizedDescription),
                ])
                return
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                appOpenAd = ad
                appOpenAd?.fullScreenContentDelegate = self
                adLogger.info("App open ad loaded successfully")
            }
        }
    }

    @discardableResult
    func showAppOpenAdIfAvailable(completion: (() -> Void)? = nil) -> Bool {
        guard shouldShowAds, let ad = appOpenAd else {
            completion?()
            return false
        }

        guard let rootVC = topViewController() else {
            completion?()
            return false
        }

        onAppOpenAdDismissed = completion
        isShowingAd = true
        ad.present(from: rootVC)
        adLogger.info("Presenting app open ad")
        return true
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
    func scheduleNativeAd() {
        guard canShowNativeAd, nativeAd != nil else { return }

        lastNativeAdTime = Date()
        nativeAdShowCount += 1

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            guard self.nativeAd != nil else { return }
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

    // MARK: - Helpers

    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
            let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        var top = rootVC
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

// MARK: - FullScreenContentDelegate (开屏广告)

extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_: FullScreenPresentingAd) {
        Task { @MainActor in
            isShowingAd = false
            adLogger.info("App open ad dismissed")
            appOpenAd = nil
            preloadAppOpenAd()
            onAppOpenAdDismissed?()
            onAppOpenAdDismissed = nil
        }
    }

    nonisolated func ad(_: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            isShowingAd = false
            adLogger.warning("App open ad failed to present", metadata: [
                "error": .string(error.localizedDescription),
            ])
            appOpenAd = nil
            preloadAppOpenAd()
            onAppOpenAdDismissed?()
            onAppOpenAdDismissed = nil
        }
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
