import SwiftUI

struct AddContactEditorContent: View {
    @Binding var avatar: Data?
    @Binding var name: String
    @Binding var selectedCategory: RelationshipCategory?
    @Binding var selectedTag: String
    @Binding var birthdayMonth: Int
    @Binding var birthdayDay: Int
    @Binding var hasBirthday: Bool
    @Binding var birthdayIsLunar: Bool
    @Binding var birthdayReminderEnabled: Bool
    @Binding var phone: String
    @Binding var location: String
    @Binding var note: String

    let screenName: String
    let onImportContacts: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                AddContactAvatarSection(avatar: $avatar, name: name)
                AddContactFormSection(
                    name: $name,
                    selectedCategory: $selectedCategory,
                    selectedTag: $selectedTag,
                    birthdayMonth: $birthdayMonth,
                    birthdayDay: $birthdayDay,
                    hasBirthday: $hasBirthday,
                    birthdayIsLunar: $birthdayIsLunar,
                    birthdayReminderEnabled: $birthdayReminderEnabled,
                    phone: $phone,
                    location: $location,
                    note: $note,
                    onImportContacts: onImportContacts
                )
            }
            .padding(.vertical, 16)
            .padding(.bottom, 80)
        }
    }
}

private struct AddContactAvatarSection: View {
    @Binding var avatar: Data?
    let name: String

    var body: some View {
        HStack {
            Spacer()
            AvatarImagePicker(imageData: $avatar, name: name)
            Spacer()
        }
    }
}

private struct AddContactFormSection: View {
    @Binding var name: String
    @Binding var selectedCategory: RelationshipCategory?
    @Binding var selectedTag: String
    @Binding var birthdayMonth: Int
    @Binding var birthdayDay: Int
    @Binding var hasBirthday: Bool
    @Binding var birthdayIsLunar: Bool
    @Binding var birthdayReminderEnabled: Bool
    @Binding var phone: String
    @Binding var location: String
    @Binding var note: String

    let onImportContacts: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            AddContactField(label: String(localized: "contact.add.name")) {
                TextField(
                    String(localized: "contact.add.namePlaceholder"),
                    text: $name
                )
                .textFieldStyle(StandardTextFieldStyle())
                .accessibilityIdentifier("contact.add.nameField")
            }

            AddContactField(label: String(localized: "contact.add.relation")) {
                RelationTagPicker(
                    selectedCategory: $selectedCategory,
                    selectedTag: $selectedTag
                )
            }

            AddContactBirthdayField(
                birthdayMonth: $birthdayMonth,
                birthdayDay: $birthdayDay,
                hasBirthday: $hasBirthday,
                birthdayIsLunar: $birthdayIsLunar,
                birthdayReminderEnabled: $birthdayReminderEnabled
            )

            AddContactPhoneField(
                phone: $phone,
                onImportContacts: onImportContacts
            )

            AddContactField(label: String(localized: "contact.add.location")) {
                TextField(
                    String(localized: "contact.add.locationPlaceholder"),
                    text: $location
                )
                .textFieldStyle(StandardTextFieldStyle())
                .accessibilityIdentifier("contact.add.locationField")
            }

            AddContactNotesField(note: $note)
        }
        .padding(.horizontal, 16)
    }
}

private struct AddContactField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            content
        }
    }
}

private struct AddContactBirthdayField: View {
    @Binding var birthdayMonth: Int
    @Binding var birthdayDay: Int
    @Binding var hasBirthday: Bool
    @Binding var birthdayIsLunar: Bool
    @Binding var birthdayReminderEnabled: Bool

    /// 农历月名
    private static let lunarMonths = (1 ... 12).map { m in
        LunarCalendarHelper.monthNames[m] ?? "\(m)月"
    }

    /// 农历日名
    private static let lunarDays = (1 ... 30).map { d in
        LunarCalendarHelper.dayNames[d] ?? "\(d)日"
    }

    /// 公历月名
    private static let gregorianMonths = (1 ... 12).map { "\($0)月" }
    /// 公历日名（最大 31 日）
    private static let gregorianDays = (1 ... 31).map { "\($0)日" }

    private var monthList: [String] {
        birthdayIsLunar ? Self.lunarMonths : Self.gregorianMonths
    }

    private var dayList: [String] {
        birthdayIsLunar ? Self.lunarDays : Self.gregorianDays
    }

    private var maxDay: Int {
        birthdayIsLunar ? 30 : 31
    }

    var body: some View {
        AddContactField(label: String(localized: "contact.add.birthday")) {
            VStack(spacing: 10) {
                // Row 1: 公历/农历切换 + 月日 Picker（始终可见，无需触发）
                HStack(spacing: 8) {
                    // 公历/农历 pill 切换
                    HStack(spacing: 0) {
                        calendarTypeButton(
                            title: String(localized: "contact.add.birthday.gregorian"),
                            isSelected: !birthdayIsLunar
                        ) {
                            guard birthdayIsLunar else { return }
                            if hasBirthday {
                                if let converted = LunarCalendarHelper.lunarToGregorian(month: birthdayMonth, day: birthdayDay) {
                                    birthdayMonth = converted.month
                                    birthdayDay = converted.day
                                    birthdayIsLunar = false
                                }
                                // 转换失败时保持农历不切换
                            } else {
                                birthdayIsLunar = false
                            }
                        }
                        calendarTypeButton(
                            title: String(localized: "contact.add.birthday.lunar"),
                            isSelected: birthdayIsLunar
                        ) {
                            guard !birthdayIsLunar else { return }
                            if hasBirthday {
                                if let converted = LunarCalendarHelper.gregorianToLunar(month: birthdayMonth, day: birthdayDay) {
                                    birthdayMonth = converted.month
                                    birthdayDay = min(converted.day, 30)
                                    birthdayIsLunar = true
                                }
                                // 转换失败时保持公历不切换
                            } else {
                                birthdayIsLunar = true
                            }
                        }
                    }
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(DesignSystem.Colors.border, lineWidth: 1))

                    Spacer()

                    // 月 Picker
                    Picker("", selection: $birthdayMonth) {
                        ForEach(1 ... 12, id: \.self) { m in
                            Text(monthList[m - 1]).tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(DesignSystem.Colors.primary)
                    .onChange(of: birthdayMonth) { _, _ in hasBirthday = true }

                    // 日 Picker
                    Picker("", selection: $birthdayDay) {
                        ForEach(1 ... maxDay, id: \.self) { d in
                            Text(dayList[d - 1]).tag(d)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(DesignSystem.Colors.primary)
                    .onChange(of: birthdayDay) { _, _ in hasBirthday = true }

                    // 已设置生日时显示清除按钮
                    if hasBirthday {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hasBirthday = false
                                birthdayIsLunar = false
                                birthdayReminderEnabled = false
                                birthdayMonth = 1
                                birthdayDay = 1
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )

                // Row 2: 生日提醒开关（仅在已设置生日时显示）
                if hasBirthday {
                    BirthdayReminderRow(
                        isEnabled: birthdayReminderEnabled,
                        onToggle: { birthdayReminderEnabled.toggle() }
                    )
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func calendarTypeButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.small)
                .foregroundStyle(isSelected ? DesignSystem.Colors.bgSurface : DesignSystem.Colors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? DesignSystem.Colors.primary : Color.clear)
        }
    }
}

private struct AddContactPhoneField: View {
    @Binding var phone: String
    let onImportContacts: () -> Void

    var body: some View {
        AddContactField(label: String(localized: "contact.add.phone")) {
            HStack {
                Spacer()

                Button(action: onImportContacts) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.rectangle")
                            .font(DesignSystem.Typography.small)
                        Text(String(localized: "contact.add.importFromContacts"))
                            .font(DesignSystem.Typography.small)
                    }
                    .foregroundStyle(DesignSystem.Colors.primary)
                }
            }

            TextField(
                String(localized: "contact.add.phonePlaceholder"),
                text: $phone
            )
            .textFieldStyle(StandardTextFieldStyle())
            .keyboardType(.phonePad)
        }
    }
}

private struct AddContactNotesField: View {
    @Binding var note: String

    var body: some View {
        AddContactField(label: String(localized: "contact.add.notes")) {
            TextEditor(text: $note)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if note.isEmpty {
                        Text(String(localized: "contact.add.notesPlaceholder"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
}

struct AddContactSaveBar: View {
    let action: () -> Void

    var body: some View {
        Button(String(localized: "contact.add.saveContact"), action: action)
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("contact.add.saveButton")
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .background(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.bgPage.opacity(0),
                        DesignSystem.Colors.bgPage,
                    ],
                    startPoint: .top,
                    endPoint: .init(x: 0.5, y: 0.3)
                )
                .ignoresSafeArea()
            )
    }
}
