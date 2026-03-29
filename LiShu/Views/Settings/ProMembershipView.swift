import SwiftUI
import StoreKit

struct ProMembershipView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var selectedProductID: String = SubscriptionManager.yearlyID
    @State private var showError = false
    @State private var isPurchasing = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                heroCard
                featuresSection
                if !subscriptionManager.isPro {
                    pricingSection
                    purchaseButton
                    termsFooter
                } else {
                    activeSubscriptionCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(String(localized: "pro.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if subscriptionManager.products.isEmpty && !subscriptionManager.isPro {
                await subscriptionManager.reloadProducts()
            }
        }
        .alert(String(localized: "pro.purchase.error"), isPresented: $showError) {
            Button(String(localized: "common.ok")) {}
        } message: {
            Text(subscriptionManager.errorMessage ?? "")
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(DesignSystem.Colors.accentGold)
                        .font(.system(size: 14))
                    Text("PRO MEMBER")
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.accentGold)
                        .fontWeight(.semibold)
                        .tracking(1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "pro.title"))
                        .font(DesignSystem.Typography.title1)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.bold)

                    Text(String(localized: "pro.heroSubtitle"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)

            Image(systemName: "crown.fill")
                .font(.system(size: 90))
                .foregroundStyle(DesignSystem.Colors.textPrimary.opacity(0.05))
                .padding(.trailing, 16)
                .padding(.bottom, 8)
        }
        .background(
            LinearGradient(
                colors: [DesignSystem.Colors.proGradientStart, DesignSystem.Colors.proGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.accentGold.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "pro.features.title"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            VStack(spacing: 0) {
                featureRow(
                    icon: "infinity",
                    title: String(localized: "pro.feature.unlimited"),
                    subtitle: String(localized: "pro.feature.unlimited.desc")
                )
                Divider().foregroundStyle(DesignSystem.Colors.separator).padding(.leading, 56)
                featureRow(
                    icon: "chart.bar.fill",
                    title: String(localized: "pro.feature.stats"),
                    subtitle: String(localized: "pro.feature.stats.desc")
                )
                Divider().foregroundStyle(DesignSystem.Colors.separator).padding(.leading, 56)
                featureRow(
                    icon: "arrow.up.arrow.down.circle.fill",
                    title: String(localized: "pro.feature.export"),
                    subtitle: String(localized: "pro.feature.export.desc")
                )
                Divider().foregroundStyle(DesignSystem.Colors.separator).padding(.leading, 56)
                featureRow(
                    icon: "doc.viewfinder",
                    title: String(localized: "pro.feature.ocr"),
                    subtitle: String(localized: "pro.feature.ocr.desc")
                )
                Divider().foregroundStyle(DesignSystem.Colors.separator).padding(.leading, 56)
                featureRow(
                    icon: "icloud.fill",
                    title: String(localized: "pro.feature.sync"),
                    subtitle: String(localized: "pro.feature.sync.desc")
                )
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(DesignSystem.Colors.accentGold)
                .frame(width: 36, height: 36)
                .background(DesignSystem.Colors.accentGold.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()

            Image(systemName: subscriptionManager.isPro ? "checkmark.circle.fill" : "lock.fill")
                .font(.system(size: 18))
                .foregroundStyle(DesignSystem.Colors.accentGold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "pro.pricing.title"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if subscriptionManager.products.isEmpty && subscriptionManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if subscriptionManager.products.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                    Text(String(localized: "pro.pricing.loadError"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await subscriptionManager.reloadProducts() }
                    } label: {
                        Text(String(localized: "common.retry"))
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 10) {
                    if let yearly = subscriptionManager.yearlyProduct {
                        pricingCard(
                            product: yearly,
                            badge: nil,
                            trialText: freeTrialText(for: yearly)
                        )
                    }
                    if let monthly = subscriptionManager.monthlyProduct {
                        pricingCard(product: monthly, badge: nil, trialText: nil)
                    }
                    if let lifetime = subscriptionManager.lifetimeProduct {
                        pricingCard(product: lifetime, badge: String(localized: "pro.pricing.bestValue"), trialText: nil)
                    }
                }
            }
        }
    }

    private func freeTrialText(for product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        let days = offer.period.value * (offer.period.unit == .day ? 1 : offer.period.unit == .week ? 7 : 30)
        return String(format: String(localized: "pro.freeTrial %lld"), Int64(days))
    }

    private func pricingCard(product: Product, badge: String?, trialText: String?) -> some View {
        let isSelected = selectedProductID == product.id

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedProductID = product.id
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? DesignSystem.Colors.accentGold : DesignSystem.Colors.textTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(localizedProductName(product))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .fontWeight(.semibold)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignSystem.Colors.primary)
                                .clipShape(Capsule())
                        }
                    }

                    if let trialText {
                        Text(trialText)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.accentGold)
                    } else {
                        Text(localizedProductDescription(product))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(localizedPrice(product))
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.bold)

                    if product.type == .autoRenewable,
                       let period = product.subscription?.subscriptionPeriod {
                        Text(periodUnitText(period))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    } else if product.type == .nonConsumable {
                        Text(String(localized: "pro.plan.lifetime.unit"))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }
            .padding(16)
            .background(isSelected ? DesignSystem.Colors.proGradientEnd : DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                    .stroke(
                        isSelected ? DesignSystem.Colors.accentGold.opacity(0.5) : DesignSystem.Colors.border.opacity(0.5),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func periodUnitText(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .month: String(localized: "pro.period.month")
        case .year: String(localized: "pro.period.year")
        case .week: String(localized: "pro.period.week")
        case .day: String(localized: "pro.period.day")
        @unknown default: ""
        }
    }

    private func localizedProductName(_ product: Product) -> String {
        switch product.id {
        case SubscriptionManager.monthlyID: String(localized: "pro.plan.monthly")
        case SubscriptionManager.yearlyID: String(localized: "pro.plan.yearly")
        case SubscriptionManager.lifetimeID: String(localized: "pro.plan.lifetime")
        default: product.displayName
        }
    }

    private func localizedProductDescription(_ product: Product) -> String {
        switch product.id {
        case SubscriptionManager.monthlyID: String(localized: "pro.plan.monthly.desc")
        case SubscriptionManager.yearlyID: String(localized: "pro.plan.yearly.desc")
        case SubscriptionManager.lifetimeID: String(localized: "pro.plan.lifetime.desc")
        default: product.description
        }
    }

    private func localizedPrice(_ product: Product) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: product.price as NSDecimalNumber) ?? product.displayPrice
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button {
                Task { await handlePurchase() }
            } label: {
                HStack(spacing: 8) {
                    if isPurchasing {
                        ProgressView()
                            .tint(DesignSystem.Colors.textOnPrimary)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))
                        Text(String(localized: "pro.purchase.action"))
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isPurchasing || subscriptionManager.products.isEmpty)

            Button {
                Task { await handleRestore() }
            } label: {
                Text(String(localized: "pro.purchase.restore"))
            }
            .buttonStyle(GhostButtonStyle())
            .disabled(isPurchasing)
        }
    }

    private func handlePurchase() async {
        guard let product = subscriptionManager.products.first(where: { $0.id == selectedProductID }) else { return }
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
        if subscriptionManager.isPro {
            dismiss()
        } else if subscriptionManager.errorMessage != nil {
            showError = true
        }
    }

    // MARK: - Active Subscription Card

    private var activeSubscriptionCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.accentGold)

            Text(String(localized: "pro.status.active"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if let planName = subscriptionManager.currentSubscriptionName {
                Text(planName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            #if DEBUG
            Button(String(localized: "DEBUG: 清除购买状态")) {
                subscriptionManager.debugClearPurchases()
            }
            .font(DesignSystem.Typography.small)
            .foregroundStyle(.red)
            .padding(.top, 8)
            #endif
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    // MARK: - Terms Footer

    private var termsFooter: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                Text(String(localized: "pro.terms.payment"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)

                Text(String(localized: "pro.terms.autoRenew"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)

                Text(String(localized: "pro.terms.manage"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)

            HStack(spacing: 12) {
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Text(String(localized: "pro.terms.privacy"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .contentShape(Rectangle())
                }

                Text("·")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                NavigationLink {
                    TermsOfServiceView()
                } label: {
                    Text(String(localized: "pro.terms.terms"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .contentShape(Rectangle())
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ProMembershipView()
            .environment(SubscriptionManager.shared)
    }
}
