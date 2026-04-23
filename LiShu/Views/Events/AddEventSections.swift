import PhotosUI
import SwiftData
import SwiftUI

struct AddEventFormView: View {
    @Bindable var viewModel: AddEventViewModel
    @Binding var selectedCoverItem: PhotosPickerItem?

    let screenName: String
    let navigationTitleText: String
    let contacts: [Contact]
    let onSave: () -> Void
    var onCreateContact: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    AddEventTextFieldSection(
                        title: String(localized: "event.add.name"),
                        placeholder: String(localized: "event.add.namePlaceholder"),
                        text: $viewModel.name
                    )

                    AddEventCoverImageSection(
                        coverImageData: viewModel.coverImageData,
                        selectedCoverItem: $selectedCoverItem
                    )

                    AddEventTypeSection(
                        selectedType: viewModel.eventType,
                        screenName: screenName,
                        onSelectType: selectType(_:)
                    )

                    AddEventDateSection(date: $viewModel.date)

                    if viewModel.hostMode == .guest {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle(String(localized: "event.add.primaryContact"))

                            if let contact = viewModel.primaryContact {
                                ContactIdentitySelectorCard(contact: contact)
                            }

                            ContactAvatarSelectorStrip(
                                contacts: contacts,
                                selectedContactID: viewModel.primaryContact?.persistentModelID,
                                accessibilityIdentifier: "event.add.contactSelector",
                                onSelectContact: { viewModel.primaryContact = $0 },
                                onCreateContact: { onCreateContact?() }
                            )
                        }
                    }

                    AddEventTextFieldSection(
                        title: String(localized: "event.add.location"),
                        placeholder: String(localized: "event.add.locationPlaceholder"),
                        text: $viewModel.location
                    )

                    AddEventNotesSection(text: $viewModel.note)
                }
                .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
                .padding(.vertical, DesignSystem.Spacing.block)
            }

            AddEventActionBar(
                isSaveEnabled: viewModel.isValid,
                onSave: onSave
            )
        }
    }

    private func selectType(_ type: EventType) {
        viewModel.eventType = type
        InteractionLogger.tap(
            screen: screenName,
            target: "events.editor.type.\(type.rawValue)"
        )
    }
}

private struct AddEventCoverImageSection: View {
    let coverImageData: Data?
    @Binding var selectedCoverItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(String(localized: "event.add.coverImage"))

            PhotosPicker(selection: $selectedCoverItem, matching: .images) {
                Group {
                    if let coverImageData {
                        DecodedImageView(
                            data: coverImageData,
                            maxPixelSize: ImagePipeline.pixelSize(for: CGSize(width: 360, height: 140))
                        )
                        .scaledToFill()
                    } else {
                        AddEventCoverPlaceholder()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                .background(DesignSystem.Colors.bgSurface)
            }
        }
    }
}

private struct AddEventCoverPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera")
                .font(DesignSystem.Typography.title1)
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text(String(localized: "event.add.selectCover"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .strokeBorder(
                    DesignSystem.Colors.border,
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
        )
    }
}

private struct AddEventTypeSection: View {
    let selectedType: EventType
    let screenName: String
    let onSelectType: (EventType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(String(localized: "event.add.type"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EventType.allCases, id: \.self) { type in
                        Button {
                            onSelectType(type)
                        } label: {
                            AddEventTypeChip(
                                type: type,
                                isSelected: selectedType == type
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct AddEventTypeChip: View {
    let type: EventType
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: type.iconName)
                .font(DesignSystem.Typography.caption)
            Text(type.displayName)
                .font(DesignSystem.Typography.caption)
        }
        .foregroundStyle(isSelected ? DesignSystem.Colors.bgSurface : DesignSystem.Colors.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.bgCard)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border,
                    lineWidth: 1
                )
        )
    }
}

private struct AddEventDateSection: View {
    @Binding var date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(String(localized: "event.add.date"))
            WeekStripDatePicker(selectedDate: $date)
        }
    }
}

private struct AddEventNotesSection: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(String(localized: "event.add.notes"))

            TextEditor(text: $text)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .frame(minHeight: 80)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
        }
    }
}

private struct AddEventTextFieldSection: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(title)

            TextField(placeholder, text: $text)
                .textFieldStyle(StandardTextFieldStyle())
        }
    }
}

private struct AddEventActionBar: View {
    let isSaveEnabled: Bool
    let onSave: () -> Void

    var body: some View {
        Button(String(localized: "common.save"), action: onSave)
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isSaveEnabled)
            .opacity(isSaveEnabled ? 1 : 0.6)
            .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
            .padding(.vertical, 12)
    }
}

private func sectionTitle(_ text: String) -> some View {
    Text(text)
        .font(DesignSystem.Typography.caption)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
        .fontWeight(.semibold)
}
