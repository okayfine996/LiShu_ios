import PhotosUI
import SwiftData
import SwiftUI

struct AddRecordFormView: View {
    let viewModel: AddRecordViewModel
    let locksContextToInitialEvent: Bool
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    let continuousSaveMessage: String?
    let onCreateContact: () -> Void
    let onCreateEvent: () -> Void
    let onSave: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignSystem.Spacing.section) {
                if let continuousSaveMessage {
                    RecordInlineSuccessBanner(message: continuousSaveMessage)
                }
                if let selectedEvent = viewModel.selectedEvent, viewModel.contextSelection == .event {
                    AddRecordCurrentEventSection(event: selectedEvent)
                }
                AddRecordContactSection(viewModel: viewModel, onCreateContact: onCreateContact)
                AddRecordRecordTypeSection(viewModel: viewModel)
                if !locksContextToInitialEvent {
                    AddRecordContextSelectionSection(viewModel: viewModel)
                }
                if viewModel.contextSelection == .event {
                    if !locksContextToInitialEvent {
                        AddRecordEventSelectionSection(viewModel: viewModel, onCreateEvent: onCreateEvent)
                    }
                } else {
                    AddRecordDailyTagSection(viewModel: viewModel)
                }
                AddRecordInteractionSection(viewModel: viewModel)
                RelationshipWeightSelector(selectedWeight: relationshipWeightBinding)
                RecordDateSection(date: dateBinding)
                RecordPhotosSection(existingPhotoData: photoDataItems, selectedPhotoItems: $selectedPhotoItems)
                RecordNotesInputSection(note: noteBinding)
                AddRecordConfirmSection(
                    title: viewModel.confirmButtonTitle,
                    isEnabled: viewModel.isValid,
                    onSave: onSave
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, DesignSystem.Spacing.block)
            .padding(.bottom, 32)
        }
    }

    private var relationshipWeightBinding: Binding<RelationshipWeight> {
        Binding(
            get: { viewModel.relationshipWeight },
            set: { viewModel.relationshipWeight = $0 }
        )
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { viewModel.date },
            set: { viewModel.date = $0 }
        )
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { viewModel.note },
            set: { viewModel.note = $0 }
        )
    }

    private var photoDataItems: [Data] {
        let existing = (viewModel.editingRecord?.photos ?? [])
            .sorted(by: { $0.createdAt < $1.createdAt })
            .map(\.imageData)
        return existing + viewModel.newPhotoItems.map(\.data)
    }
}

private struct AddRecordCurrentEventSection: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.currentEvent"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            RecordEventSummaryCard(
                title: String(localized: "record.add.currentEvent"),
                event: event
            )
        }
    }
}

private struct AddRecordContactSection: View {
    let viewModel: AddRecordViewModel
    let onCreateContact: () -> Void

    var body: some View {
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
    }

    private func selectContact(_ contact: Contact) {
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.selectedContact = contact
        }
    }
}

private struct AddRecordConfirmSection: View {
    let title: String
    let isEnabled: Bool
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onSave) {
                Text(title)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : DesignSystem.Effects.disabledOpacity)
            .padding(.top, 4)

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
