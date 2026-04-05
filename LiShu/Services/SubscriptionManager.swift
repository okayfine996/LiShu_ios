import Foundation
import Logging
import StoreKit
import SwiftData

private let subscriptionLogger = PulseDiagnostics.makeLogger(label: "billing.subscription")

enum UsageLimits {
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

    var isPro: Bool {
        !purchasedProductIDs.isEmpty
    }

    @ObservationIgnored private var updateListenerTask: Task<Void, Error>?
    @ObservationIgnored private var expirationCheckTask: Task<Void, Never>?

    static let monthlyID = "com.finefine.LiShu.pro.monthly.v2"
    static let yearlyID = "com.finefine.LiShu.pro.yearly.v2"
    static let lifetimeID = "com.finefine.LiShu.pro.lifetime.v2"

    private let productIDs: Set<String> = [
        monthlyID, yearlyID, lifetimeID,
    ]

    // MARK: - Sorted products for display

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == Self.yearlyID }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == Self.lifetimeID }
    }

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
                   transaction.productID != Self.lifetimeID
                {
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
        subscriptionLogger.notice("Reloading StoreKit products")
        await loadProducts()
    }

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            products = try await Product.products(for: productIDs)
            if products.isEmpty {
                subscriptionLogger.warning("StoreKit returned no products", metadata: [
                    "expected_product_ids": .string(productIDs.sorted().joined(separator: ",")),
                ])
            } else {
                subscriptionLogger.info("StoreKit products loaded", metadata: [
                    "count": .stringConvertible(products.count),
                    "product_ids": .string(products.map(\.id).sorted().joined(separator: ",")),
                ])
            }
        } catch {
            // 网络类错误给用户更友好的提示
            if let skError = error as? StoreKitError, case .networkError = skError {
                errorMessage = String(localized: "pro.pricing.networkError")
            } else {
                errorMessage = error.localizedDescription
            }
            if let skError = error as? StoreKitError {
                switch skError {
                case let .networkError(urlError):
                    subscriptionLogger.error("StoreKit product load failed", metadata: [
                        "reason": .string("network_error"),
                        "error": .string(urlError.localizedDescription),
                    ])
                case let .systemError(underlying):
                    subscriptionLogger.error("StoreKit product load failed", metadata: [
                        "reason": .string("system_error"),
                        "error": .string(String(describing: underlying)),
                    ])
                case .notAvailableInStorefront:
                    subscriptionLogger.warning("StoreKit products unavailable in storefront")
                case .notEntitled:
                    subscriptionLogger.error("StoreKit product load failed", metadata: [
                        "reason": .string("not_entitled"),
                    ])
                case .userCancelled, .unknown, .unsupported:
                    subscriptionLogger.error("StoreKit product load failed", metadata: [
                        "reason": .string(String(describing: skError)),
                    ])
                @unknown default:
                    subscriptionLogger.error("StoreKit product load failed", metadata: [
                        "reason": .string("unknown_default"),
                        "error": .string(String(describing: skError)),
                    ])
                }
            } else {
                subscriptionLogger.error("StoreKit product load failed", metadata: [
                    "error": .string(String(describing: error)),
                ])
            }
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        subscriptionLogger.notice("Starting purchase", metadata: [
            "product_id": .string(product.id),
        ])

        do {
            let result = try await product.purchase()

            switch result {
            case let .success(verification):
                let transaction = try checkVerified(verification)
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                isLoading = false
                subscriptionLogger.notice("Purchase completed", metadata: [
                    "product_id": .string(transaction.productID),
                ])
                return true

            case .userCancelled:
                isLoading = false
                subscriptionLogger.info("Purchase cancelled by user", metadata: [
                    "product_id": .string(product.id),
                ])
                return false

            case .pending:
                isLoading = false
                subscriptionLogger.notice("Purchase pending", metadata: [
                    "product_id": .string(product.id),
                ])
                return false

            @unknown default:
                isLoading = false
                subscriptionLogger.warning("Purchase returned unknown result", metadata: [
                    "product_id": .string(product.id),
                ])
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            subscriptionLogger.error("Purchase failed", metadata: [
                "product_id": .string(product.id),
                "error": .string(error.localizedDescription),
            ])
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        subscriptionLogger.notice("Starting purchase restore")

        do {
            try await AppStore.sync()
            await checkEntitlements()
            subscriptionLogger.notice("Purchase restore finished", metadata: [
                "active_product_count": .stringConvertible(purchasedProductIDs.count),
            ])
        } catch {
            errorMessage = error.localizedDescription
            subscriptionLogger.error("Purchase restore failed", metadata: [
                "error": .string(error.localizedDescription),
            ])
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
                    if nearestExpiration.map({ exp < $0 }) ?? true {
                        nearestExpiration = exp
                    }
                }
            }
        }

        purchasedProductIDs = activeIDs
        scheduleExpirationRecheck(at: nearestExpiration)
        subscriptionLogger.debug("Entitlements refreshed", metadata: [
            "active_product_count": .stringConvertible(activeIDs.count),
            "active_product_ids": .string(activeIDs.sorted().joined(separator: ",")),
            "nearest_expiration": .string(nearestExpiration.map { ISO8601DateFormatter().string(from: $0) } ?? "none"),
        ])
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
            subscriptionLogger.debug("Running scheduled entitlement refresh")
            await self?.checkEntitlements()
        }
    }

    // MARK: - Transaction Updates

    private func listenForTransactionUpdates() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    subscriptionLogger.notice("Transaction update received", metadata: [
                        "product_id": .string(transaction.productID),
                    ])
                    await transaction.finish()
                }
                await self?.checkEntitlements()
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case let .unverified(_, error):
            throw error
        case let .verified(value):
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
