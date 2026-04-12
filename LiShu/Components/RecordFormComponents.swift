import SwiftUI

struct RecordEventSummaryCard: View {
    let title: String
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.stackTight) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            HStack(spacing: DesignSystem.Spacing.block) {
                EventCoverView(
                    coverImage: event.coverImage,
                    eventType: event.type,
                    size: 52,
                    placeholderBackground: DesignSystem.Colors.bgSurface
                )
//                .overlay(
//                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
//                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
//                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(event.type.displayName)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .clipShape(Capsule())

                        Text(formattedEventDate)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(14)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    private var formattedEventDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: event.date)
    }
}

struct MonetaryAmountInputCard: View {
    @Binding var amount: String
    var fieldAccessibilityIdentifier: String?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(localized: "record.add.amount"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.bottom, -4)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("¥")
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.primary)

                TextField(String(localized: "record.add.amountPlaceholder"), text: $amount)
                    .font(DesignSystem.Typography.display)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier(fieldAccessibilityIdentifier ?? "")
            }

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary.opacity(0.6))

                Text(String(localized: "record.add.amountHint"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.bgInput)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.tag))
        }
        .padding(20)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .shadow(color: DesignSystem.Colors.textPrimary.opacity(0.03), radius: 4, y: 2)
    }
}

struct PaymentMethodSelector: View {
    @Binding var selectedMethod: PaymentMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.paymentMethod"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .tracking(1)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            HStack(spacing: 8) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    paymentMethodCapsule(method)
                }
                Spacer()
            }
        }
    }

    private func paymentMethodCapsule(_ method: PaymentMethod) -> some View {
        let isSelected = selectedMethod == method
        return Button {
            selectedMethod = method
        } label: {
            Text(paymentMethodName(method))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(isSelected ? DesignSystem.Colors.primary.opacity(0.08) : DesignSystem.Colors.bgSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border.opacity(0.5),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func paymentMethodName(_ method: PaymentMethod) -> String {
        switch method {
        case .cash: String(localized: "payment.cash")
        case .wechat: String(localized: "payment.wechat")
        case .alipay: String(localized: "payment.alipay")
        }
    }
}

struct RelationshipWeightSelector: View {
    @Binding var selectedWeight: RelationshipWeight

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "record.add.relationshipWeight"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            Text(String(localized: "record.add.relationshipWeight.description"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(DesignSystem.Colors.bgInput)
                            .frame(height: 8)

                        Capsule()
                            .fill(DesignSystem.Colors.primary.opacity(0.18))
                            .frame(width: progressWidth(totalWidth: geometry.size.width), height: 8)

                        HStack(spacing: 0) {
                            ForEach(RelationshipWeight.allCases, id: \.rawValue) { weight in
                                weightButton(weight)
                            }
                        }
                    }
                }
                .frame(height: 32)

                HStack(alignment: .top, spacing: 0) {
                    ForEach(RelationshipWeight.allCases, id: \.rawValue) { weight in
                        Text(weight.displayName)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(
                                selectedWeight == weight
                                    ? DesignSystem.Colors.textPrimary
                                    : DesignSystem.Colors.textTertiary
                            )
                            .fontWeight(selectedWeight == weight ? .semibold : .medium)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(16)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        let steps = max(RelationshipWeight.allCases.count - 1, 1)
        let currentIndex = RelationshipWeight.allCases.firstIndex(of: selectedWeight) ?? 0
        return (totalWidth / CGFloat(steps)) * CGFloat(currentIndex)
    }

    private func weightButton(_ weight: RelationshipWeight) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedWeight = weight
            }
        } label: {
            let isSelected = selectedWeight == weight
            ZStack {
                if isSelected {
                    Circle()
                        .fill(DesignSystem.Colors.bgSurface)
                        .frame(width: 32, height: 32)
                        .shadow(color: DesignSystem.Colors.primary.opacity(0.12), radius: 6, y: 2)
                }

                Circle()
                    .fill(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.bgSurface)
                    .frame(width: isSelected ? 22 : 14, height: isSelected ? 22 : 14)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? DesignSystem.Colors.bgSurface : DesignSystem.Colors.border,
                                lineWidth: isSelected ? 4 : 1
                            )
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        RecordEventSummaryCard(
            title: String(localized: "record.add.currentEvent"),
            event: Event(name: "我的婚礼", type: .wedding, hostMode: .host, date: .now, location: "锦绣悦府")
        )

        PreviewAmountCard()

        PreviewPaymentMethodSelector()

        PreviewRelationshipWeightSelector()
    }
    .padding()
    .background(DesignSystem.Colors.bgPage)
}

private struct PreviewAmountCard: View {
    @State private var amount = "888"

    var body: some View {
        MonetaryAmountInputCard(amount: $amount)
    }
}

private struct PreviewPaymentMethodSelector: View {
    @State private var method: PaymentMethod = .wechat

    var body: some View {
        PaymentMethodSelector(selectedMethod: $method)
    }
}

private struct PreviewRelationshipWeightSelector: View {
    @State private var weight: RelationshipWeight = .reciprocal

    var body: some View {
        RelationshipWeightSelector(selectedWeight: $weight)
    }
}
