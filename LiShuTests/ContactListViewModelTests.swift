import Foundation
@testable import LiShu
import SwiftData
import Testing

@MainActor
struct ContactListViewModelTests {
    @Test("load returns 3 contacts in state")
    func testLoadContacts() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "张三")
        let c2 = SampleData.contact(name: "李四")
        let c3 = SampleData.contact(name: "王五")
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(c3)
        try db.context.save()

        let vm = ContactListViewModel()
        vm.loadContacts(context: db.context)

        #expect(vm.state.value != nil)
        #expect(vm.state.value?.count == 3)
    }

    @Test("totalCount reflects all loaded contacts")
    func testTotalCount() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "张三")
        let c2 = SampleData.contact(name: "李四")
        let c3 = SampleData.contact(name: "王五")
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(c3)
        try db.context.save()

        let vm = ContactListViewModel()
        vm.loadContacts(context: db.context)

        #expect(vm.totalCount == 3)
    }

    @Test("searchText filters contacts by name")
    func searchFilter() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "张三")
        let c2 = SampleData.contact(name: "李四")
        db.context.insert(c1)
        db.context.insert(c2)
        try db.context.save()

        let vm = ContactListViewModel()
        vm.loadContacts(context: db.context)
        vm.searchText = "张"

        #expect(vm.filteredContacts.count == 1)
        #expect(vm.filteredContacts.first?.name == "张三")
    }

    @Test("selectedFilter=family shows only 家人 contacts")
    func circleFilter() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "张三", category: "家人")
        let c2 = SampleData.contact(name: "李四", category: "社会")
        db.context.insert(c1)
        db.context.insert(c2)
        try db.context.save()

        let vm = ContactListViewModel()
        vm.loadContacts(context: db.context)
        vm.selectedFilter = .family

        #expect(vm.filteredContacts.count == 1)
        #expect(vm.filteredContacts.first?.category == "家人")
    }

    @Test("groupedContacts groups by category")
    func testGroupedContacts() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "张三", category: "家人")
        let c2 = SampleData.contact(name: "李四", category: "社会")
        let c3 = SampleData.contact(name: "王五", category: "家人")
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(c3)
        try db.context.save()

        let vm = ContactListViewModel()
        vm.loadContacts(context: db.context)

        let groups = vm.groupedContacts
        #expect(groups.count >= 2)
        let familyGroup = groups.first { $0.id == "家人" }
        #expect(familyGroup != nil)
        #expect(familyGroup?.contacts.count == 2)
        let socialGroup = groups.first { $0.id == "社会" }
        #expect(socialGroup != nil)
        #expect(socialGroup?.contacts.count == 1)
    }

    @Test("deleteContact decreases count")
    func testDeleteContact() throws {
        let db = try TestDB()
        let c1 = SampleData.contact(name: "张三")
        let c2 = SampleData.contact(name: "李四")
        db.context.insert(c1)
        db.context.insert(c2)
        try db.context.save()

        let vm = ContactListViewModel()
        vm.loadContacts(context: db.context)
        #expect(vm.totalCount == 2)

        vm.deleteContact(c1, context: db.context)
        #expect(vm.totalCount == 1)
    }
}
