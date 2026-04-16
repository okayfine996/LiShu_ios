import PhotosUI
import SwiftData
import SwiftUI

struct AddLedgerReceiptFormView: View {
    let viewModel: AddLedgerReceiptViewModel
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    let continuousSaveMessage: String?
    let onCreateContact: () -> Void
    let onSaveAndContinue: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.section) {
                if let continuousSaveMessage {
                    RecordInlineSuccessBanner(message: continuousSaveMessage)
                }
                if let selectedEvent = viewModel.selectedEvent {
                    RecordEventSummaryCard(
                        title: String(localized: "record.add.currentLedger"),
                        event: selectedEvent
                    )
                }
                VStack(spacing: DesignSystem.Spacing.block) {
                    if let selectedContact = viewModel.selectedContact {
                        ContactIdentitySelectorCard(contact: selectedContact)
                    }

                    ContactAvatarSelectorStrip(
                        contacts: viewModel.allContacts,
                        selectedContactID: viewModel.selectedContact?.persistentModelID,
                        accessibilityIdentifier: "record.add.contactSelector",
                        onSelectContact: selectContact,
                        onCreateContact: onCreateContact
                    )
                }
                MonetaryAmountInputCard(
                    amount: monetaryAmountBinding,
                    fieldAccessibilityIdentifier: "record.add.amountField"
                )
                PaymentMethodSelector(selectedMethod: paymentMethodBinding)
                RelationshipWeightSelector(selectedWeight: relationshipWeightBinding)
                RecordDateSection(date: dateBinding)
                RecordPhotosSection(existingPhotoData: viewModel.newPhotoItems.map(\.data), selectedPhotoItems: $selectedPhotoItems)
                RecordNotesInputSection(note: noteBinding)
                AddLedgerReceiptContinueSection(
                    isEnabled: viewModel.isValid,
                    onSaveAndContinue: onSaveAndContinue
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, DesignSystem.Spacing.block)
            .padding(.bottom, 32)
        }
    }

    private var monetaryAmountBinding: Binding<String> {
        Binding(get: { viewModel.monetaryAmount }, set: { viewModel.monetaryAmount = $0 })
    }

    private var paymentMethodBinding: Binding<PaymentMethod> {
        Binding(get: { viewModel.monetaryPaymentMethod }, set: { viewModel.monetaryPaymentMethod = $0 })
    }

    private var relationshipWeightBinding: Binding<RelationshipWeight> {
        Binding(get: { viewModel.relationshipWeight }, set: { viewModel.relationshipWeight = $0 })
    }

    private var dateBinding: Binding<Date> {
        Binding(get: { viewModel.date }, set: { viewModel.date = $0 })
    }

    private var noteBinding: Binding<String> {
        Binding(get: { viewModel.note }, set: { viewModel.note = $0 })
    }

    private func selectContact(_ contact: Contact) {
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.selectedContact = contact
        }
    }
}

private struct AddLedgerReceiptContinueSection: View {
    let isEnabled: Bool
    let onSaveAndContinue: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onSaveAndContinue) {
                Text(String(localized: "record.add.saveAndContinue"))
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : DesignSystem.Effects.disabledOpacity)

            if !isEnabled {
                Text(String(localized: "record.add.saveDisabledHint"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignSystem.Colors.bgInput)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.tag))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
