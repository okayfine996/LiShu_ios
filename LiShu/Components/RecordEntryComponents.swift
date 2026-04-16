import PhotosUI
import SwiftData
import SwiftUI

struct ContactIdentitySelectorCard: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(imageData: contact.avatar, name: contact.name, size: 52)
                .overlay(
                    Circle()
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(contact.name)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    if !contact.relation.isEmpty {
                        Text(contact.relation)
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }

                Text(String(localized: "record.add.contactLabel"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(14)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}

struct ContactAvatarSelectorStrip: View {
    let contacts: [Contact]
    let selectedContactID: PersistentIdentifier?
    let accessibilityIdentifier: String
    let onSelectContact: (Contact) -> Void
    let onCreateContact: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            Text(String(localized: "record.add.selectContact"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .tracking(1.5)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(contacts) { contact in
                        ContactAvatarSelectorItem(
                            contact: contact,
                            isSelected: selectedContactID == contact.persistentModelID,
                            isDimmed: selectedContactID != nil && selectedContactID != contact.persistentModelID,
                            onTap: { onSelectContact(contact) }
                        )
                    }

                    NewContactTriggerButton(action: onCreateContact)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct ContactAvatarSelectorItem: View {
    let contact: Contact
    let isSelected: Bool
    let isDimmed: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Circle()
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(DesignSystem.Effects.selectedFillOpacity) : .clear)
                    .frame(width: 60, height: 60)
                    .overlay {
                        AvatarView(
                            imageData: contact.avatar,
                            name: contact.name,
                            size: 56,
                            placeholderBackground: DesignSystem.Colors.bgSurface
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                        .frame(width: 60, height: 60)
                    }
                    .shadow(
                        color: isSelected ? DesignSystem.Colors.primary.opacity(DesignSystem.Effects.selectedShadowOpacity) : .clear,
                        radius: DesignSystem.Effects.selectedShadowRadius,
                        y: DesignSystem.Effects.selectedShadowYOffset
                    )

                Text(contact.name)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    .fontWeight(isSelected ? .medium : .regular)
                    .lineLimit(1)
            }
            .frame(minWidth: 72)
            .opacity(isDimmed ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("record.add.contact.\(contact.name)")
    }
}

struct NewContactTriggerButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.bgSurface)
                        .frame(width: 56, height: 56)
                    Circle()
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.badge.plus")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
                .frame(width: 60, height: 60)

                Text(String(localized: "record.add.newContact"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(minWidth: 72)
        }
        .buttonStyle(.plain)
    }
}

struct RecordPhotosSection: View {
    let existingPhotoData: [Data]
    @Binding var selectedPhotoItems: [PhotosPickerItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.photos"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(existingPhotoData.enumerated()), id: \.offset) { _, data in
                        photoThumbnail(imageData: data)
                    }
                    addPhotoButton
                }
                .padding(12)
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }

    private func photoThumbnail(imageData: Data) -> some View {
        Group {
            if !imageData.isEmpty {
                DecodedImageView(data: imageData, maxPixelSize: ImagePipeline.Preset.thumbnailMaxPixelSize)
                    .scaledToFill()
            }
        }
        .frame(width: 80, height: 80)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }

    private var addPhotoButton: some View {
        PhotosPicker(
            selection: $selectedPhotoItems,
            maxSelectionCount: 20,
            matching: .images
        ) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(DesignSystem.Typography.title3)
                Text(String(localized: "record.add.addPhoto"))
                    .font(DesignSystem.Typography.small)
            }
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .frame(width: 80, height: 80)
            .background(DesignSystem.Colors.bgTag)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
        }
    }
}

struct RecordNotesInputSection: View {
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "record.add.notes"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            TextEditor(text: $note)
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
