//
//  AddContactViewModelTests.swift
//  LiShuTests
//

import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct AddContactViewModelTests {
    @Test func isValidWithEmptyName() {
        let vm = AddContactViewModel()
        vm.name = ""
        #expect(vm.isValid == false)
    }

    @Test func isValidWithWhitespaceName() {
        let vm = AddContactViewModel()
        vm.name = "   "
        #expect(vm.isValid == false)
    }

    @Test func isValidWithValidName() {
        let vm = AddContactViewModel()
        vm.name = "张三"
        #expect(vm.isValid == true)
    }

    @Test func saveContactSuccess() throws {
        let db = try TestDB()
        let vm = AddContactViewModel()
        vm.name = "李四"
        vm.phone = "13800138000"

        #expect(vm.saveContact(context: db.context) == true)

        let descriptor = FetchDescriptor<Contact>(
            predicate: #Predicate<Contact> { $0.name == "李四" }
        )
        let contacts = try db.context.fetch(descriptor)
        #expect(contacts.count == 1)
        #expect(contacts[0].name == "李四")
    }

    @Test func saveContactInvalid() throws {
        let db = try TestDB()
        let vm = AddContactViewModel()
        vm.name = ""

        #expect(vm.saveContact(context: db.context) == false)
        #expect(vm.showValidationAlert == true)
    }

    @Test func configureWithContact() throws {
        let db = try TestDB()
        let contact = Contact(name: "王五", phone: "13900139000", relation: "朋友", category: "社会", circle: 3, birthday: Date(), note: "备注")
        db.context.insert(contact)

        let vm = AddContactViewModel()
        vm.configure(with: contact)

        #expect(vm.editingContact === contact)
        #expect(vm.name == "王五")
        #expect(vm.phone == "13900139000")
        #expect(vm.note == "备注")
    }

    @Test func saveContactEditMode() throws {
        let db = try TestDB()
        let contact = Contact(name: "赵六", relation: "同事", category: "社会")
        db.context.insert(contact)
        try db.context.save()

        let vm = AddContactViewModel()
        vm.configure(with: contact)
        vm.name = "赵六 updated"

        #expect(vm.saveContact(context: db.context) == true)

        let descriptor = FetchDescriptor<Contact>()
        let contacts = try db.context.fetch(descriptor)
        #expect(contacts.count == 1)
        #expect(contacts[0].name == "赵六 updated")
    }

    @Test func configureReadsLunarBirthdayDate() throws {
        let db = try TestDB()
        // 农历八月十五 → dateFromLunar 构造 Date 存入，configure 应提取回 (8, 15)
        let birthday = try #require(LunarCalendarHelper.dateFromLunar(month: 8, day: 15))
        let contact = Contact(
            name: "农历生日测试",
            birthday: birthday,
            birthdayIsLunar: true,
            birthdayReminderEnabled: true
        )
        db.context.insert(contact)

        let vm = AddContactViewModel()
        vm.configure(with: contact)

        #expect(vm.birthdayMonth == 8)
        #expect(vm.birthdayDay == 15)
        #expect(vm.birthdayIsLunar == true)
        #expect(vm.birthdayReminderEnabled == true)
        #expect(vm.hasBirthday == true)
    }

    @Test func configureReadsGregorianBirthdayDate() throws {
        let db = try TestDB()
        let date = try #require(Calendar.current.date(from: DateComponents(year: 1990, month: 5, day: 20)))
        let contact = Contact(name: "公历生日测试", birthday: date, birthdayIsLunar: false)
        db.context.insert(contact)

        let vm = AddContactViewModel()
        vm.configure(with: contact)

        #expect(vm.hasBirthday == true)
        #expect(vm.birthdayMonth == 5)
        #expect(vm.birthdayDay == 20)
        #expect(vm.birthdayIsLunar == false)
    }

    @Test func configureReadsLunarFromStoredGregorianDate() throws {
        let db = try TestDB()
        // 2024-09-17 公历 = 农历八月十五，验证 lunarMonthDay 提取正确
        let date = try #require(Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 17)))
        let contact = Contact(name: "农历存公历Date测试", birthday: date, birthdayIsLunar: true)
        db.context.insert(contact)

        let vm = AddContactViewModel()
        vm.configure(with: contact)

        #expect(vm.hasBirthday == true)
        #expect(vm.birthdayMonth == 8)
        #expect(vm.birthdayDay == 15)
        #expect(vm.birthdayIsLunar == true)
    }

    @Test func saveContactWritesBirthdayDate() throws {
        let db = try TestDB()
        let vm = AddContactViewModel()
        vm.name = "生日保存测试"
        vm.hasBirthday = true
        vm.birthdayMonth = 3
        vm.birthdayDay = 5
        vm.birthdayIsLunar = true
        vm.birthdayReminderEnabled = true

        #expect(vm.saveContact(context: db.context) == true)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        let saved = contacts[0]
        let savedDate = try #require(saved.birthday)
        #expect(saved.birthdayIsLunar == true)
        #expect(saved.birthdayReminderEnabled == true)
        // 验证存储的 Date 还原出正确农历月日
        let md = try #require(LunarCalendarHelper.lunarMonthDay(from: savedDate))
        #expect(md.month == 3)
        #expect(md.day == 5)
    }

    @Test func saveContactWithNoBirthdayClearsBirthdayDate() throws {
        let db = try TestDB()
        let vm = AddContactViewModel()
        vm.name = "无生日测试"
        vm.hasBirthday = false
        vm.birthdayMonth = 5
        vm.birthdayDay = 10
        vm.birthdayIsLunar = true
        vm.birthdayReminderEnabled = true

        #expect(vm.saveContact(context: db.context) == true)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        #expect(contacts[0].birthday == nil)
        #expect(contacts[0].birthdayIsLunar == false)
        #expect(contacts[0].birthdayReminderEnabled == false)
    }

    @Test func saveContactReminderDisabledDoesNotEnable() throws {
        let db = try TestDB()
        let vm = AddContactViewModel()
        vm.name = "提醒关闭测试"
        vm.hasBirthday = true
        vm.birthdayMonth = 8
        vm.birthdayDay = 15
        vm.birthdayIsLunar = false
        vm.birthdayReminderEnabled = false

        #expect(vm.saveContact(context: db.context) == true)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        #expect(contacts[0].birthdayReminderEnabled == false)
    }

    @Test func editContactPreservesBirthdayDate() throws {
        let db = try TestDB()
        let birthday = LunarCalendarHelper.dateFromLunar(month: 6, day: 1)
        let contact = Contact(
            name: "编辑测试",
            birthday: birthday,
            birthdayIsLunar: true,
            birthdayReminderEnabled: true
        )
        db.context.insert(contact)
        try db.context.save()

        let vm = AddContactViewModel()
        vm.configure(with: contact)
        vm.name = "编辑测试 updated"

        #expect(vm.saveContact(context: db.context) == true)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        let saved = contacts[0]
        let savedDate = try #require(saved.birthday)
        #expect(saved.birthdayIsLunar == true)
        #expect(saved.birthdayReminderEnabled == true)
        let md = try #require(LunarCalendarHelper.lunarMonthDay(from: savedDate))
        #expect(md.month == 6)
        #expect(md.day == 1)
    }

    /// birthday == nil 时，isLunar/reminderEnabled 应被重置为 false
    @Test func configureNoBirthdayResetsFlags() throws {
        let db = try TestDB()
        let contact = Contact(
            name: "无生日农历标志",
            birthdayIsLunar: true,
            birthdayReminderEnabled: true
        )
        db.context.insert(contact)

        let vm = AddContactViewModel()
        vm.configure(with: contact)

        #expect(vm.hasBirthday == false)
        #expect(vm.birthdayIsLunar == false)
        #expect(vm.birthdayReminderEnabled == false)
    }

    @Test func saveContactCompressesAvatar() throws {
        let db = try TestDB()
        let vm = AddContactViewModel()
        vm.name = "头像测试"
        vm.avatar = SampleImages.makePNGData(width: 2400, height: 2400)

        #expect(vm.saveContact(context: db.context) == true)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        let avatar = try #require(contacts[0].avatar)
        let dimensions = try #require(ImagePipeline.imageDimensions(from: avatar))
        #expect(dimensions.width <= CGFloat(ImagePipeline.Preset.avatarMaxPixelSize))
        #expect(dimensions.height <= CGFloat(ImagePipeline.Preset.avatarMaxPixelSize))
    }
}
