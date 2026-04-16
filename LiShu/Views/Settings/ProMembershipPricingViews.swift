import StoreKit
import SwiftUI

struct ProMembershipPricingSection: View {
    let subscriptionManager: SubscriptionManager
    @Binding var selectedProductID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "pro.pricing.title"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if subscriptionManager.products.isEmpty, subscriptionManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if subscriptionManager.products.isEmpty {
                ProMembershipPricingErrorView(retry: reloadProducts)
            } else {
                VStack(spacing: 10) {
                    if let yearly = subscriptionManager.yearlyProduct {
                        ProMembershipPricingCard(
                            product: yearly,
                            isSelected: selectedProductID == yearly.id,
                            badge: nil,
                            trialText: ProMembershipProductFormatter.freeTrialText(for: yearly),
                            onSelect: select(yearly.id)
                        )
                    }

                    if let monthly = subscriptionManager.monthlyProduct {
                        ProMembershipPricingCard(
                            product: monthly,
                            isSelected: selectedProductID == monthly.id,
                            badge: nil,
                            trialText: nil,
                            onSelect: select(monthly.id)
                        )
                    }

                    if let lifetime = subscriptionManager.lifetimeProduct {
                        ProMembershipPricingCard(
                            product: lifetime,
                            isSelected: selectedProductID == lifetime.id,
                            badge: String(localized: "pro.pricing.bestValue"),
                            trialText: nil,
                            onSelect: select(lifetime.id)
                        )
                    }
                }
            }
        }
    }

    private func reloadProducts() {
        Task {
            await subscriptionManager.reloadProducts()
        }
    }

    private func select(_ productID: String) -> () -> Void {
        {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedProductID = productID
            }
        }
    }
}

struct ProMembershipPurchaseActions: View {
    let isPurchasing: Bool
    let hasProducts: Bool
    let onPurchaseTap: () -> Void
    let onRestoreTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onPurchaseTap) {
                HStack(spacing: 8) {
                    if isPurchasing {
                        ProgressView()
                            .tint(DesignSystem.Colors.textOnPrimary)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(DesignSystem.Typography.body)
                        Text(String(localized: "pro.purchase.action"))
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isPurchasing || !hasProducts)

            Button(String(localized: "pro.purchase.restore"), action: onRestoreTap)
                .buttonStyle(GhostButtonStyle())
                .disabled(isPurchasing)
        }
    }
}

private struct ProMembershipPricingErrorView: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text(String(localized: "pro.pricing.loadError"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button(String(localized: "common.retry"), action: retry)
                .buttonStyle(SecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

private struct ProMembershipPricingCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let trialText: String?
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        isSelected ? DesignSystem.Colors.accentGold : DesignSystem.Colors.textTertiary
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(ProMembershipProductFormatter.localizedProductName(product))
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
                        Text(ProMembershipProductFormatter.localizedProductDescription(product))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(ProMembershipProductFormatter.localizedPrice(product))
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.bold)

                    if product.type == .autoRenewable,
                       let period = product.subscription?.subscriptionPeriod
                    {
                        Text(ProMembershipProductFormatter.periodUnitText(period))
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
                        isSelected
                            ? DesignSystem.Colors.accentGold.opacity(0.5)
                            : DesignSystem.Colors.border.opacity(0.5),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private enum ProMembershipProductFormatter {
    static func freeTrialText(for product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        let days = offer.period.value * (
            offer.period.unit == .day ? 1 : offer.period.unit == .week ? 7 : 30
        )
        return String(format: String(localized: "pro.freeTrial %lld"), Int64(days))
    }

    static func periodUnitText(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .month:
            String(localized: "pro.period.month")
        case .year:
            String(localized: "pro.period.year")
        case .week:
            String(localized: "pro.period.week")
        case .day:
            String(localized: "pro.period.day")
        @unknown default:
            ""
        }
    }

    static func localizedProductName(_ product: Product) -> String {
        switch product.id {
        case SubscriptionManager.monthlyID:
            String(localized: "pro.plan.monthly")
        case SubscriptionManager.yearlyID:
            String(localized: "pro.plan.yearly")
        case SubscriptionManager.lifetimeID:
            String(localized: "pro.plan.lifetime")
        default:
            product.displayName
        }
    }

    static func localizedProductDescription(_ product: Product) -> String {
        switch product.id {
        case SubscriptionManager.monthlyID:
            String(localized: "pro.plan.monthly.desc")
        case SubscriptionManager.yearlyID:
            String(localized: "pro.plan.yearly.desc")
        case SubscriptionManager.lifetimeID:
            String(localized: "pro.plan.lifetime.desc")
        default:
            product.description
        }
    }

    static func localizedPrice(_ product: Product) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: product.price as NSDecimalNumber) ?? product.displayPrice
    }
}
