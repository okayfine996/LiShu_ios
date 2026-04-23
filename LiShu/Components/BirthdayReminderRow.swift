import SwiftUI

/// 生日提醒开关行，供联系人详情页和编辑表单复用。
/// 调用方负责外层背景/边框（如需卡片样式）。
struct BirthdayReminderRow: View {
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isEnabled ? "bell.fill" : "bell.slash.fill")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(isEnabled ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                .frame(width: 24, height: 24)

            Text(String(localized: "contact.add.birthdayReminder"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Toggle("", isOn: Binding(get: { isEnabled }, set: { _ in onToggle() }))
                .labelsHidden()
                .tint(DesignSystem.Colors.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    VStack(spacing: 16) {
        BirthdayReminderRow(isEnabled: true, onToggle: {})
        BirthdayReminderRow(isEnabled: false, onToggle: {})
    }
    .padding()
    .background(DesignSystem.Colors.bgSurface)
}
