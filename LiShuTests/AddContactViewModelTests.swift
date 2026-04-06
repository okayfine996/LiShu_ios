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
