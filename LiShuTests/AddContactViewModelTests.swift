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

    @Test func configureReadsNewBirthdayFields() throws {
        let db = try TestDB()
        let contact = Contact(
            name: "农历生日测试",
            birthdayMonth: 8,
            birthdayDay: 15,
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

    @Test func configureMigratesLegacyGregorianBirthday() throws {
        let db = try TestDB()
        // 旧数据：只有 birthday: Date，birthdayMonth == 0
        let legacyDate = try #require(Calendar.current.date(from: DateComponents(year: 1990, month: 5, day: 20)))
        let contact = Contact(name: "旧公历数据", birthday: legacyDate, birthdayIsLunar: false)
        db.context.insert(contact)

        let vm = AddContactViewModel()
        vm.configure(with: contact)

        #expect(vm.hasBirthday == true)
        #expect(vm.birthdayMonth == 5)
        #expect(vm.birthdayDay == 20)
        #expect(vm.birthdayIsLunar == false)
    }

    @Test func configureMigratesLegacyLunarBirthday() throws {
        let db = try TestDB()
        // 旧农历数据：2024-09-17 公历 = 农历八月十五
        let legacyDate = try #require(Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 17)))
        let contact = Contact(name: "旧农历数据", birthday: legacyDate, birthdayIsLunar: true)
        db.context.insert(contact)

        let vm = AddContactViewModel()
        vm.configure(with: contact)

        #expect(vm.hasBirthday == true)
        #expect(vm.birthdayMonth == 8)
        #expect(vm.birthdayDay == 15)
        #expect(vm.birthdayIsLunar == true)
    }

    @Test func saveContactWritesMonthDayFields() throws {
        let db = try TestDB()
        let vm = AddContactViewModel()
        vm.name = "月日保存测试"
        vm.hasBirthday = true
        vm.birthdayMonth = 3
        vm.birthdayDay = 5
        vm.birthdayIsLunar = true
        vm.birthdayReminderEnabled = true

        #expect(vm.saveContact(context: db.context) == true)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        #expect(contacts[0].birthdayMonth == 3)
        #expect(contacts[0].birthdayDay == 5)
        #expect(contacts[0].birthdayIsLunar == true)
        #expect(contacts[0].birthdayReminderEnabled == true)
        #expect(contacts[0].birthday == nil) // 新数据不写 birthday 字段
    }

    @Test func saveContactWithNoBirthdayClearsBirthdayFields() throws {
        let db = try TestDB()
        let vm = AddContactViewModel()
        vm.name = "无生日测试"
        vm.hasBirthday = false
        vm.birthdayMonth = 5 // 即使有值，无生日时应存 0
        vm.birthdayDay = 10
        vm.birthdayIsLunar = true
        vm.birthdayReminderEnabled = true

        #expect(vm.saveContact(context: db.context) == true)

        let contacts = try db.context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        #expect(contacts[0].birthdayMonth == 0)
        #expect(contacts[0].birthdayDay == 0)
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

    @Test func editContactPreservesBirthdayFields() throws {
        let db = try TestDB()
        let contact = Contact(
            name: "编辑测试",
            birthdayMonth: 6,
            birthdayDay: 1,
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
        #expect(contacts[0].birthdayMonth == 6)
        #expect(contacts[0].birthdayDay == 1)
        #expect(contacts[0].birthdayIsLunar == true)
        #expect(contacts[0].birthdayReminderEnabled == true)
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
