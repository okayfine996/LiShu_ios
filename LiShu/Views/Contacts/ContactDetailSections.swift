import SwiftData
import SwiftUI

struct ContactDetailProfileSection: View {
    let contact: Contact

    var body: some View {
        VStack(spacing: 8) {
            AvatarView(imageData: contact.avatar, name: contact.name, size: 80)
                .overlay {
                    Circle()
                        .stroke(DesignSystem.Colors.bgSurface, lineWidth: 1)
                }

            Text(contact.name)
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if !contact.category.isEmpty || !contact.relation.isEmpty {
                HStack(spacing: 6) {
                    if !contact.relation.isEmpty {
                        ContactDetailTag(
                            title: contact.relation,
                            foreground: DesignSystem.Colors.primary,
                            background: DesignSystem.Colors.primary.opacity(0.12)
                        )
                    }
                    if !contact.category.isEmpty {
                        ContactDetailTag(
                            title: contact.category,
                            foreground: DesignSystem.Colors.textSecondary,
                            background: DesignSystem.Colors.bgTag
                        )
                    }
                }
            }

            if !contact.location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(DesignSystem.Typography.small)
                    Text(contact.location)
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }
}

struct ContactDetailPersonalInfoSection: View {
    let contact: Contact
    let viewModel: ContactDetailViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "contact.detail.personalInfo"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                if let birthdayValue = birthdayText(for: contact) {
                    ContactDetailInfoRow(
                        icon: "birthday.cake.fill",
                        label: String(localized: "contact.add.birthday"),
                        value: birthdayValue
                    )
                    ContactDetailInfoDivider()
                    BirthdayReminderRow(
                        isEnabled: contact.birthdayReminderEnabled,
                        onToggle: {
                            viewModel.toggleBirthdayReminder(contact: contact, context: modelContext)
                        }
                    )
                    ContactDetailInfoDivider()
                }

                ContactDetailInfoRow(
                    icon: "circle.grid.2x2.fill",
                    label: String(localized: "contact.detail.circle"),
                    value: viewModel.circleText(contact.circle)
                )

                if !contact.phone.isEmpty {
                    ContactDetailInfoDivider()
                    ContactDetailInfoRow(
                        icon: "phone.fill",
                        label: String(localized: "contact.add.phone"),
                        value: contact.phone
                    )
                }

                if !contact.note.isEmpty {
                    ContactDetailInfoDivider()
                    ContactDetailInfoRow(
                        icon: "note.text",
                        label: String(localized: "contact.add.notes"),
                        value: contact.note
                    )
                }
            }
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard))
            .padding(.horizontal, 16)
        }
        .alert(
            String(localized: "notification.permission.denied.title"),
            isPresented: Binding(
                get: { viewModel.showNotificationPermissionAlert },
                set: { viewModel.showNotificationPermissionAlert = $0 }
            )
        ) {
            Button(String(localized: "notification.permission.denied.openSettings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "notification.permission.denied.message"))
        }
        .alert(
            String(localized: "common.error"),
            isPresented: Binding(
                get: { viewModel.saveError != nil },
                set: { if !$0 { viewModel.saveError = nil } }
            )
        ) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            if let error = viewModel.saveError {
                Text(error)
            }
        }
    }

    private func birthdayText(for contact: Contact) -> String? {
        guard let date = contact.birthday else { return nil }
        if contact.birthdayIsLunar, let md = LunarCalendarHelper.lunarMonthDay(from: date) {
            return LunarCalendarHelper.format(month: md.month, day: md.day)
        } else {
            let md = LunarCalendarHelper.gregorianMonthDay(from: date)
            return LunarCalendarHelper.formatGregorian(month: md.month, day: md.day)
        }
    }
}

private struct ContactDetailTag: View {
    let title: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(title)
            .font(DesignSystem.Typography.small)
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
    }
}

private struct ContactDetailInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 24, height: 24)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct ContactDetailInfoDivider: View {
    var body: some View {
        Divider()
            .background(DesignSystem.Colors.separator)
            .padding(.leading, 52)
    }
}
