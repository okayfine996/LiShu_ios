import Foundation
import Testing
import SwiftData
@testable import LiShu

@MainActor
struct AddCustomFestivalViewModelTests {
    @Test func testSaveCreatesCustomFestivalAndPreference() throws {
        let db = try TestDB()
        let contact = SampleData.contact(name: "妈妈", relation: "母亲", category: RelationshipCategory.family.rawValue, circle: 1)
        db.context.insert(contact)
        try db.context.save()

        let viewModel = AddCustomFestivalViewModel()
        viewModel.name = "乔迁纪念日"
        viewModel.calendarType = .solar
        viewModel.month = 10
        viewModel.day = 1
        viewModel.isReminderEnabled = true
        viewModel.useDefaultRecipients = false
        viewModel.selectedContactIDs = [contact.identifier]

        #expect(viewModel.save(context: db.context, preferences: []) == true)

        let festivals = try db.context.fetch(FetchDescriptor<CustomFestival>())
        let preferences = try db.context.fetch(FetchDescriptor<FestivalReminderPreference>())

        #expect(festivals.count == 1)
        #expect(festivals[0].name == "乔迁纪念日")
        #expect(festivals[0].calendarType == FestivalCalendarType.solar)
        #expect(preferences.count == 1)
        #expect(preferences[0].festivalID == festivals[0].identifier)
        #expect(preferences[0].useDefaultRecipients == false)
        #expect(preferences[0].recipientContactIDs == [contact.identifier])
    }
}
