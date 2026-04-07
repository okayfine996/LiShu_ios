import Foundation
import SwiftData

@Observable
class FestivalEditorViewModel {
    var editingFestival: UserFestival?
    var name: String = ""
    var coverImage: Data?
    var recurrence: FestivalRecurrence = .annualGregorian
    var reminderEnabled: Bool = true
    var contactSelectionMode: FestivalContactSelectionMode = .recommendedOnly
    var gregorianMonth: Int = 1
    var gregorianDay: Int = 1
    var lunarMonth: Int = 1
    var lunarDay: Int = 1
    var oneTimeDate: Date = .now
    var selectedContactIDs: Set<PersistentIdentifier> = []
    var contacts: [Contact] = []

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func loadContacts(context: ModelContext) {
        contacts = ((try? context.fetch(FetchDescriptor<Contact>(sortBy: [SortDescriptor(\.name)]))) ?? [])
    }

    func configure(with festival: UserFestival, context: ModelContext) {
        editingFestival = festival
        name = festival.name
        coverImage = festival.coverImage
        recurrence = festival.recurrence
        reminderEnabled = festival.reminderEnabled
        contactSelectionMode = festival.contactSelectionMode
        gregorianMonth = festival.gregorianMonth ?? 1
        gregorianDay = festival.gregorianDay ?? 1
        lunarMonth = festival.lunarMonth ?? 1
        lunarDay = festival.lunarDay ?? 1
        oneTimeDate = festival.oneTimeDate ?? .now
        let route = FestivalRoutePayload.userFestival(festival.persistentModelID)
        selectedContactIDs = Set(FestivalService.preferredContacts(for: route, context: context).map(\.persistentModelID))
    }

    @discardableResult
    func save(context: ModelContext) -> UserFestival? {
        guard isValid else { return nil }

        let festival = editingFestival ?? UserFestival(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            recurrence: recurrence
        )

        festival.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        festival.coverImage = coverImage
        festival.recurrence = recurrence
        festival.reminderEnabled = reminderEnabled
        festival.contactSelectionMode = contactSelectionMode
        festival.gregorianMonth = recurrence == .annualGregorian ? gregorianMonth : nil
        festival.gregorianDay = recurrence == .annualGregorian ? gregorianDay : nil
        festival.lunarMonth = recurrence == .annualLunar ? lunarMonth : nil
        festival.lunarDay = recurrence == .annualLunar ? lunarDay : nil
        festival.oneTimeDate = recurrence == .oneTime ? Calendar.current.startOfDay(for: oneTimeDate) : nil

        if editingFestival == nil {
            context.insert(festival)
        }

        do {
            try context.save()
            let route = FestivalRoutePayload.userFestival(festival.persistentModelID)
            let selectedContacts = contacts.filter { selectedContactIDs.contains($0.persistentModelID) }
            FestivalService.replacePreferredContacts(for: route, contacts: selectedContacts, context: context)
            FestivalService.setContactSelectionMode(contactSelectionMode, for: route, context: context)
            return festival
        } catch {
            return nil
        }
    }

    func delete(context: ModelContext) -> Bool {
        guard let editingFestival else { return false }
        let route = FestivalRoutePayload.userFestival(editingFestival.persistentModelID)
        FestivalService.replacePreferredContacts(for: route, contacts: [], context: context)
        context.delete(editingFestival)
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
}
