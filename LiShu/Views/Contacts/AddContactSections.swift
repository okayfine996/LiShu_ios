import SwiftUI

struct AddContactEditorContent: View {
    @Binding var avatar: Data?
    @Binding var name: String
    @Binding var selectedCategory: RelationshipCategory?
    @Binding var selectedTag: String
    @Binding var birthdayDate: Date
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
                    birthdayDate: $birthdayDate,
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
    @Binding var birthdayDate: Date
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
                birthdayDate: $birthdayDate,
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
    @Binding var birthdayDate: Date
    @Binding var hasBirthday: Bool
    @Binding var birthdayIsLunar: Bool
    @Binding var birthdayReminderEnabled: Bool

    var body: some View {
        AddContactField(label: String(localized: "contact.add.birthday")) {
            VStack(spacing: 10) {
                if hasBirthday {
                    // 已设置：显示完整选择器行
                    HStack(spacing: 8) {
                        // 公历/农历 pill 切换
                        HStack(spacing: 0) {
                            calendarTypeButton(
                                title: String(localized: "contact.add.birthday.gregorian"),
                                isSelected: !birthdayIsLunar
                            ) { birthdayIsLunar = false }
                            calendarTypeButton(
                                title: String(localized: "contact.add.birthday.lunar"),
                                isSelected: birthdayIsLunar
                            ) { birthdayIsLunar = true }
                        }
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(DesignSystem.Colors.border, lineWidth: 1))

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            DatePicker("", selection: $birthdayDate, displayedComponents: [.date])
                                .labelsHidden()
                                .environment(\.calendar, Calendar(identifier: birthdayIsLunar ? .chinese : .gregorian))
                                .environment(\.locale, birthdayIsLunar ? Locale(identifier: "zh_CN") : .current)
                                .tint(DesignSystem.Colors.primary)
                            if let annotation = calendarAnnotation {
                                Text(annotation)
                                    .font(DesignSystem.Typography.small)
                                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                            }
                        }

                        Button {
                            hasBirthday = false
                            birthdayIsLunar = false
                            birthdayReminderEnabled = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
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
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))

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
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                } else {
                    // 未设置：显示添加按钮
                    Button {
                        hasBirthday = true
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(DesignSystem.Colors.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                }
            }
            .animation(.spring(duration: 0.3, bounce: 0.15), value: hasBirthday)
        }
    }

    /// 另一历法的对应日期注释：公历模式显示农历，农历模式显示公历
    private var calendarAnnotation: String? {
        if birthdayIsLunar {
            let md = LunarCalendarHelper.gregorianMonthDay(from: birthdayDate)
            return LunarCalendarHelper.formatGregorian(month: md.month, day: md.day)
        } else {
            guard let md = LunarCalendarHelper.lunarMonthDay(from: birthdayDate) else { return nil }
            return LunarCalendarHelper.format(month: md.month, day: md.day)
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
