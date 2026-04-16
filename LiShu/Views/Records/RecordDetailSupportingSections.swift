import SwiftData
import SwiftUI

struct RecordDetailNotesSection: View {
    let note: String

    var body: some View {
        if note.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                    Text(String(localized: "record.detail.notesSection"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .fontWeight(.semibold)
                }

                Text(note)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineSpacing(4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
    }
}

struct RecordDetailPhotosSection: View {
    let photos: [RecordPhoto]
    let onPhotoTap: (Data) -> Void

    var body: some View {
        if photos.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "record.detail.photos"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)
                    .padding(.leading, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(photos) { photo in
                            Button {
                                onPhotoTap(photo.imageData)
                            } label: {
                                RecordDetailPhotoThumbnail(imageData: photo.imageData)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                }
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            }
        }
    }
}

struct RecordDetailContactHistorySection: View {
    let contact: Contact?
    let contactRecordCount: Int
    let contactNetAmount: Double

    var body: some View {
        if let contact {
            VStack(alignment: .leading, spacing: 10) {
                Text(String(format: String(localized: "record.detail.contactHistory"), contact.name))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)
                    .padding(.leading, 4)

                NavigationLink {
                    ContactDetailView(contactID: contact.persistentModelID)
                } label: {
                    HStack(spacing: 12) {
                        AvatarView(imageData: contact.avatar, name: contact.name)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(String(localized: "record.detail.historySummary"))
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                                .fontWeight(.semibold)

                            Text(String(
                                format: String(localized: "record.detail.historyDetail"),
                                contactRecordCount,
                                RecordDetailFormatters.amount(contactNetAmount)
                            ))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }

                        Spacer()

                        Text(String(localized: "record.detail.viewAll"))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.primary)

                        Image(systemName: "chevron.right")
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                    .padding(14)
                    .contentShape(Rectangle())
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct RecordDetailReturnButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(DesignSystem.Typography.caption.weight(.semibold))
                Text(String(localized: "record.detail.returnGift"))
                    .font(DesignSystem.Typography.body)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

struct RecordDetailReturnSheet: View {
    let record: Record?
    @Binding var returnedAmountText: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(String(localized: "record.detail.returnGiftTitle"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if let record {
                    RecordDetailReturnSummaryCard(record: record)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "record.detail.returnAmountLabel"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .fontWeight(.semibold)

                    HStack(spacing: 8) {
                        Text("¥")
                            .font(DesignSystem.Typography.title2)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        TextField("0", text: $returnedAmountText)
                            .font(DesignSystem.Typography.title2)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .keyboardType(.decimalPad)
                    }
                    .padding(12)
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                }

                Button(action: onSave) {
                    Text(String(localized: "record.detail.confirmReturn"))
                }
                .buttonStyle(PrimaryButtonStyle())

                Spacer()
            }
            .padding(20)
            .background(DesignSystem.Colors.bgPage)
            .navigationTitle(String(localized: "record.detail.returnGift"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "common.cancel"), action: onCancel)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct RecordDetailPhotoThumbnail: View {
    let imageData: Data

    var body: some View {
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
}

private struct RecordDetailReturnSummaryCard: View {
    let record: Record

    var body: some View {
        VStack(spacing: 8) {
            RecordDetailReturnSummaryRow(
                label: String(localized: "record.detail.currentAmount"),
                value: RecordDetailFormatters.amount(record.monetaryAmount),
                valueColor: DesignSystem.Colors.textPrimary
            )

            if record.resolvedReturnedAmount > 0 {
                RecordDetailReturnSummaryRow(
                    label: String(localized: "record.detail.alreadyReturned"),
                    value: RecordDetailFormatters.amount(record.resolvedReturnedAmount),
                    valueColor: DesignSystem.Colors.accentGold
                )
            }
        }
        .padding(14)
        .background(DesignSystem.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
    }
}

private struct RecordDetailReturnSummaryRow: View {
    let label: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(valueColor)
                .fontWeight(.medium)
        }
    }
}

struct PhotoViewItem: Identifiable {
    let id = UUID()
    let data: Data
}

struct FullScreenPhotoView: View {
    let imageData: Data
    let onDismiss: () -> Void

    private var fullScreenPixelSize: Int {
        ImagePipeline.pixelSize(for: UIScreen.main.bounds.size)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if !imageData.isEmpty {
                DecodedImageView(data: imageData, maxPixelSize: fullScreenPixelSize)
                    .scaledToFit()
                    .ignoresSafeArea()
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(DesignSystem.Typography.title1)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .background(Circle().fill(DesignSystem.Colors.bgSurface.opacity(0.8)))
            }
            .padding(16)
        }
        .background(DesignSystem.Colors.overlayDark)
    }
}
