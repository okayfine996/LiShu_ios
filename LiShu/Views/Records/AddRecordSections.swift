import SwiftUI

struct AddRecordRecordTypeSection: View {
    let viewModel: AddRecordViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "record.add.recordType"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            Text(String(localized: "record.add.recordType.description"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(RecordType.allCases, id: \.self) { type in
                    recordTypeButton(type)
                }
            }
        }
    }

    private func recordTypeButton(_ type: RecordType) -> some View {
        let isSelected = viewModel.recordType == type

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.recordType = type
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                        .fill(DesignSystem.Colors.bgSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                                .stroke(
                                    isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border.opacity(0.3),
                                    lineWidth: isSelected ? 1.5 : 1
                                )
                        )
                        .shadow(color: isSelected ? DesignSystem.Colors.primary.opacity(0.08) : .clear, radius: 4, y: 2)

                    Image(systemName: type.iconName)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                }
                .frame(height: 48)

                Text(type.displayName)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
        }
        .buttonStyle(.plain)
    }
}

struct AddRecordInteractionSection: View {
    let viewModel: AddRecordViewModel
    let onOpenSmartReturnGift: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if !viewModel.isDirectionLockedBySelectedEvent {
                AddRecordDirectionSection(viewModel: viewModel)
            }
            AddRecordTypeSpecificSection(
                viewModel: viewModel,
                onOpenSmartReturnGift: onOpenSmartReturnGift
            )
        }
    }
}

private struct AddRecordDirectionSection: View {
    let viewModel: AddRecordViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            Text(String(localized: "record.add.directionSection"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            Text(String(localized: "record.add.directionSection.description"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 0) {
                directionButton(.given, title: viewModel.directionTitle(for: .given))
                directionButton(.received, title: viewModel.directionTitle(for: .received))
            }
            .padding(4)
            .background(DesignSystem.Colors.bgInput)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
        }
    }

    private func directionButton(_ direction: RecordDirection, title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.direction = direction
            }
        } label: {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(
                    viewModel.direction == direction
                        ? DesignSystem.Colors.textPrimary
                        : DesignSystem.Colors.textTertiary
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(viewModel.direction == direction ? DesignSystem.Colors.bgSurface : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.tag))
                .shadow(
                    color: viewModel.direction == direction
                        ? DesignSystem.Colors.primary.opacity(DesignSystem.Effects.selectedShadowOpacity)
                        : .clear,
                    radius: DesignSystem.Effects.selectedShadowRadius,
                    y: DesignSystem.Effects.selectedShadowYOffset
                )
        }
        .buttonStyle(.plain)
    }
}

private struct AddRecordTypeSpecificSection: View {
    let viewModel: AddRecordViewModel
    let onOpenSmartReturnGift: () -> Void

    var body: some View {
        Group {
            switch viewModel.recordType {
            case .monetary:
                VStack(spacing: 16) {
                    MonetaryAmountInputCard(
                        amount: monetaryAmountBinding,
                        fieldAccessibilityIdentifier: "record.add.amountField"
                    )
                    if let suggestion = viewModel.smartReturnGiftSuggestion {
                        SmartReturnGiftSuggestionCard(
                            suggestion: suggestion,
                            onTap: onOpenSmartReturnGift
                        )
                    }
                    PaymentMethodSelector(selectedMethod: paymentMethodBinding)
                }
            case .gift:
                VStack(spacing: 16) {
                    recordField(
                        label: String(localized: "record.add.giftName"),
                        placeholder: String(localized: "record.add.giftName.placeholder"),
                        text: giftNameBinding
                    )
                    optionalAmountField(
                        label: String(localized: "record.add.estimatedValue"),
                        text: giftEstimatedValueBinding
                    )
                }
            case .favor:
                recordTextEditor(
                    label: String(localized: "record.type.favor") + String(localized: "record.add.favorDescription.label"),
                    placeholder: String(localized: "record.add.favorDescription.favor"),
                    text: favorDescriptionBinding,
                    isOptional: false
                )
            case .banquet:
                VStack(spacing: 16) {
                    recordField(
                        label: String(localized: "record.add.banquet.location"),
                        placeholder: String(localized: "record.add.banquet.location.placeholder"),
                        text: banquetLocationBinding
                    )
                    recordTextEditor(
                        label: String(localized: "record.add.banquet.attendees"),
                        placeholder: String(localized: "record.add.banquet.attendees.placeholder"),
                        text: banquetAttendeeListBinding,
                        isOptional: false
                    )
                    recordTextEditor(
                        label: String(localized: "record.add.banquet.extraCostNotes"),
                        placeholder: String(localized: "record.add.banquet.extraCostNotes.placeholder"),
                        text: banquetExtraCostNotesBinding,
                        isOptional: true
                    )
                }
            }
        }
    }

    private var monetaryAmountBinding: Binding<String> {
        Binding(get: { viewModel.monetaryAmount }, set: { viewModel.monetaryAmount = $0 })
    }

    private var paymentMethodBinding: Binding<PaymentMethod> {
        Binding(get: { viewModel.monetaryPaymentMethod }, set: { viewModel.monetaryPaymentMethod = $0 })
    }

    private var giftNameBinding: Binding<String> {
        Binding(get: { viewModel.giftName }, set: { viewModel.giftName = $0 })
    }

    private var giftEstimatedValueBinding: Binding<String> {
        Binding(get: { viewModel.giftEstimatedValue }, set: { viewModel.giftEstimatedValue = $0 })
    }

    private var favorDescriptionBinding: Binding<String> {
        Binding(get: { viewModel.favorDesc }, set: { viewModel.favorDesc = $0 })
    }

    private var banquetLocationBinding: Binding<String> {
        Binding(get: { viewModel.banquetLocation }, set: { viewModel.banquetLocation = $0 })
    }

    private var banquetAttendeeListBinding: Binding<String> {
        Binding(get: { viewModel.banquetAttendeeList }, set: { viewModel.banquetAttendeeList = $0 })
    }

    private var banquetExtraCostNotesBinding: Binding<String> {
        Binding(get: { viewModel.banquetExtraCostNotes }, set: { viewModel.banquetExtraCostNotes = $0 })
    }

    private func recordField(label: String, placeholder: String, text: Binding<String>, isOptional: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)
                if isOptional {
                    Text(String(localized: "record.add.amountOptional"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            TextField(placeholder, text: text)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(12)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
        }
    }

    private func recordTextEditor(label: String, placeholder: String, text: Binding<String>, isOptional: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)
                if isOptional {
                    Text(String(localized: "record.add.amountOptional"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            ZStack(alignment: .topLeading) {
                if text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholder)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: text)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
            }
            .padding(12)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }

    private func optionalAmountField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)
                Text(String(localized: "record.add.amountOptional"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            HStack(spacing: 8) {
                Text("¥")
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                TextField("0", text: text)
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .keyboardType(.decimalPad)
            }
            .frame(minHeight: 36)
            .padding(12)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }
}

private struct SmartReturnGiftSuggestionCard: View {
    let suggestion: AddRecordViewModel.SmartReturnGiftSuggestionSummary
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.block) {
                Image(systemName: "sparkles")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(width: DesignSystem.Layout.smartGiftIconSize, height: DesignSystem.Layout.smartGiftIconSize)
                    .background(DesignSystem.Colors.bgIconSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.dense) {
                    Text(String(localized: "record.add.smartGift.title"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.semibold)

                    Text(
                        String(
                            format: String(localized: "record.add.smartGift.subtitle"),
                            formattedAmount(suggestion.conservativeAmount),
                            formattedAmount(suggestion.generousAmount)
                        )
                    )
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.leading)

                    Text(
                        String(
                            format: String(localized: "record.add.smartGift.reference"),
                            formattedAmount(suggestion.receivedTotal),
                            formattedAmount(suggestion.givenTotal)
                        )
                    )
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.dense) {
                    Text(
                        String(
                            format: String(localized: "record.add.smartGift.standard"),
                            formattedAmount(suggestion.standardAmount)
                        )
                    )
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .fontWeight(.semibold)

                    Image(systemName: "chevron.right")
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
            .padding(DesignSystem.Spacing.pageHorizontal)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .stroke(DesignSystem.Colors.border.opacity(0.7), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("record.add.smartGiftSuggestion")
    }

    private func formattedAmount(_ amount: Double) -> String {
        "¥" + (Self.numberFormatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount))
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}
