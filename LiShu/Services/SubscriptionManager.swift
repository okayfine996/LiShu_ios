import Foundation
import StoreKit
import SwiftData

struct UsageLimits {
    static let freeOCRPerMonth = 3
    static let freeRecordTotal = 20
    static let freeContactTotal = 20
}

@Observable
@MainActor
class SubscriptionManager {
    static let shared = SubscriptionManager()

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false
    var errorMessage: String?

    var isPro: Bool { !purchasedProductIDs.isEmpty }

    @ObservationIgnored private var updateListenerTask: Task<Void, Error>?
    @ObservationIgnored private var expirationCheckTask: Task<Void, Never>?

    static let monthlyID = "com.finefine.LiShu.pro.monthly.v2"
    static let yearlyID = "com.finefine.LiShu.pro.yearly.v2"
    static let lifetimeID = "com.finefine.LiShu.pro.lifetime.v2"

    private let productIDs: Set<String> = [
        monthlyID, yearlyID, lifetimeID
    ]

    // MARK: - Sorted products for display

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }
    var yearlyProduct: Product? { products.first { $0.id == Self.yearlyID } }
    var lifetimeProduct: Product? { products.first { $0.id == Self.lifetimeID } }

    // MARK: - Current subscription info

    var currentSubscriptionName: String? {
        guard isPro else { return nil }
        if purchasedProductIDs.contains(Self.lifetimeID) {
            return String(localized: "pro.plan.lifetime")
        } else if purchasedProductIDs.contains(Self.yearlyID) {
            return String(localized: "pro.plan.yearly")
        } else if purchasedProductIDs.contains(Self.monthlyID) {
            return String(localized: "pro.plan.monthly")
        }
        return nil
    }

    var subscriptionExpirationDate: Date? {
        get async {
            for await result in Transaction.currentEntitlements {
                if let transaction = try? result.payloadValue,
                   transaction.productID != Self.lifetimeID {
                    return transaction.expirationDate
                }
            }
            return nil
        }
    }

    // MARK: - Init

    private init() {
        updateListenerTask = listenForTransactionUpdates()
    }

    deinit {
        updateListenerTask?.cancel()
        expirationCheckTask?.cancel()
    }

    // MARK: - Load Products

    /// 强制重新拉取商品（用于首次失败或进入 Pro 页时重试）
    func reloadProducts() async {
        products = []
        errorMessage = nil
        await loadProducts()
    }

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            products = try await Product.products(for: productIDs)
            #if DEBUG
            if products.isEmpty {
                print("[LiShu] StoreKit: 加载到 0 个产品，请检查：1) Scheme 是否关联了 LiShu.storekit；2) 模拟器优先测试；3) 真机需网络连接 Apple 服务器")
            } else {
                print("[LiShu] StoreKit: 成功加载 \(products.count) 个产品")
            }
            #endif
        } catch {
            // 网络类错误给用户更友好的提示
            if let skError = error as? StoreKitError, case .networkError = skError {
                errorMessage = String(localized: "pro.pricing.networkError")
            } else {
                errorMessage = error.localizedDescription
            }
            #if DEBUG
            print("[LiShu] StoreKit 加载失败: \(error)")
            if let skError = error as? StoreKitError {
                switch skError {
                case .networkError(let urlError):
                    print("[LiShu] 网络错误: \(urlError.localizedDescription) — 请检查网络连接、关闭 VPN/代理后重试")
                case .systemError(let underlying):
                    print("[LiShu] 系统错误: \(underlying)")
                case .notAvailableInStorefront:
                    print("[LiShu] 产品在当前地区不可用")
                case .notEntitled:
                    print("[LiShu] 应用缺少 In-App Purchase 权限，请在 Xcode Signing 中启用")
                case .userCancelled, .unknown, .unsupported:
                    print("[LiShu] StoreKit 错误: \(skError)")
                @unknown default:
                    print("[LiShu] StoreKit 错误: \(skError)")
                }
            }
            #endif
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                isLoading = false
                return true

            case .userCancelled:
                isLoading = false
                return false

            case .pending:
                isLoading = false
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Check Entitlements

    func checkEntitlements() async {
        var activeIDs: Set<String> = []
        var nearestExpiration: Date?

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                activeIDs.insert(transaction.productID)
                if let exp = transaction.expirationDate {
                    if nearestExpiration == nil || exp < nearestExpiration! {
                        nearestExpiration = exp
                    }
                }
            }
        }

        purchasedProductIDs = activeIDs
        scheduleExpirationRecheck(at: nearestExpiration)
    }

    private func scheduleExpirationRecheck(at date: Date?) {
        expirationCheckTask?.cancel()
        guard let date else { return }

        let delay = date.timeIntervalSinceNow + 1
        guard delay > 0 else {
            Task { await checkEntitlements() }
            return
        }

        expirationCheckTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await self?.checkEntitlements()
        }
    }

    // MARK: - Transaction Updates

    private func listenForTransactionUpdates() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                }
                await self?.checkEntitlements()
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    // MARK: - Debug

    #if DEBUG
    func debugClearPurchases() {
        purchasedProductIDs.removeAll()
    }
    #endif

    // MARK: - Usage Limits

    func canAddRecord(context: ModelContext) -> Bool {
        guard !isPro else { return true }
        let descriptor = FetchDescriptor<Record>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count < UsageLimits.freeRecordTotal
    }

    func canAddContact(context: ModelContext) -> Bool {
        guard !isPro else { return true }
        let descriptor = FetchDescriptor<Contact>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count < UsageLimits.freeContactTotal
    }

    func canUseOCR() -> Bool {
        guard !isPro else { return true }
        resetOCRCountIfNeeded()
        return AppSettings.shared.ocrUsageCount < UsageLimits.freeOCRPerMonth
    }

    func recordOCRUsage() {
        guard !isPro else { return }
        resetOCRCountIfNeeded()
        AppSettings.shared.ocrUsageCount += 1
    }

    func remainingOCRCount() -> Int {
        guard !isPro else { return .max }
        resetOCRCountIfNeeded()
        return max(0, UsageLimits.freeOCRPerMonth - AppSettings.shared.ocrUsageCount)
    }

    private func resetOCRCountIfNeeded() {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        let settings = AppSettings.shared

        if settings.ocrUsageMonth != currentMonth || settings.ocrUsageYear != currentYear {
            settings.ocrUsageCount = 0
            settings.ocrUsageMonth = currentMonth
            settings.ocrUsageYear = currentYear
        }
    }
}
