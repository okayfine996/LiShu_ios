import StoreKit
import SwiftUI

struct ProMembershipView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(DebugOverrideManager.self) private var debugOverrides

    @State private var selectedProductID: String = SubscriptionManager.yearlyID
    @State private var showError = false
    @State private var isPurchasing = false

    private var effectiveProAccessEnabled: Bool {
        subscriptionManager.effectiveIsPro(overrides: debugOverrides)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                ProMembershipHeroCard()
                ProMembershipFeaturesSection(isUnlocked: effectiveProAccessEnabled)

                if effectiveProAccessEnabled {
                    ProMembershipActiveSubscriptionCard(
                        planName: subscriptionManager.currentSubscriptionName,
                        onDebugClearPurchases: debugClearPurchasesAction
                    )
                } else {
                    ProMembershipPricingSection(
                        subscriptionManager: subscriptionManager,
                        selectedProductID: $selectedProductID
                    )
                    ProMembershipPurchaseActions(
                        isPurchasing: isPurchasing,
                        hasProducts: !subscriptionManager.products.isEmpty,
                        onPurchaseTap: purchase,
                        onRestoreTap: restore
                    )
                    ProMembershipTermsFooter()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "pro.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheetCloseButton(action: dismiss.callAsFunction)
        .task {
            await reloadProductsIfNeeded()
        }
        .alert(String(localized: "pro.purchase.error"), isPresented: $showError) {
            Button(String(localized: "common.ok")) {}
        } message: {
            Text(subscriptionManager.errorMessage ?? "")
        }
    }

    private func reloadProductsIfNeeded() async {
        if subscriptionManager.products.isEmpty, !effectiveProAccessEnabled {
            await subscriptionManager.reloadProducts()
        }
    }

    private func purchase() {
        Task {
            await handlePurchase()
        }
    }

    private func restore() {
        Task {
            await handleRestore()
        }
    }

    private func handlePurchase() async {
        guard let product = subscriptionManager.products.first(where: { $0.id == selectedProductID }) else { return }

        // Track the click intent
        TelemetryDeckAnalytics.signal(
            TelemetryDeckAnalytics.Signal.proPurchaseClicked,
            parameters: ["product_id": selectedProductID]
        )

        isPurchasing = true
        let success = await subscriptionManager.purchase(product)
        isPurchasing = false

        if success {
            dismiss()
        } else if subscriptionManager.errorMessage != nil {
            showError = true
        }
    }

    private func handleRestore() async {
        isPurchasing = true
        await subscriptionManager.restorePurchases()
        isPurchasing = false

        if effectiveProAccessEnabled {
            dismiss()
        } else if subscriptionManager.errorMessage != nil {
            showError = true
        }
    }

    private var debugClearPurchasesAction: (() -> Void)? {
        #if DEBUG
            return {
                subscriptionManager.debugClearPurchases()
            }
        #else
            return nil
        #endif
    }
}

#Preview {
    NavigationStack {
        ProMembershipView()
            .environment(SubscriptionManager.shared)
            .environment(DebugOverrideManager.shared)
    }
}
