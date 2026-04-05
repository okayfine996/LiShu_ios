import Foundation
import SwiftData

/// 待保存的新增照片（稳定 `id` 供 `ForEach` 使用）
struct NewRecordPhotoItem: Identifiable, Equatable {
    let id: UUID
    let data: Data

    static func == (lhs: NewRecordPhotoItem, rhs: NewRecordPhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum RecordContextSelection: String, CaseIterable {
    case event = "event"
    case daily = "daily"
}

@Observable
class AddRecordViewModel {
    var editingRecord: Record?
    var direction: RecordDirection = .given
    var selectedContact: Contact?
    var selectedEvent: Event?
    var contextSelection: RecordContextSelection = .event
    var date: Date = .now
    var note: String = ""
    var contactSearchText: String = ""
    var isShowingContactPicker: Bool = false
    /// Pending photo data from PhotosPicker, converted to RecordPhoto on save
    var newPhotoItems: [NewRecordPhotoItem] = []

    var recordType: RecordType = .monetary
    var relationshipWeight: RelationshipWeight = .reciprocal

    // 类型专属表单状态
    var monetaryAmount: String = ""
    var monetaryPaymentMethod: PaymentMethod = .cash

    var giftName: String = ""
    var giftEstimatedValue: String = ""

    var favorDesc: String = ""

    var banquetLocation: String = ""
    var banquetAttendeeList: String = ""
    var banquetExtraCostNotes: String = ""

    // 日常往来标签
    var selectedDailyTag: String = ""
    var customTagInput: String = ""
    var isCreatingCustomTag: Bool = false
    var customDailyTags: [String] = []

    static let builtInDailyTags: [String] = [
        String(localized: "record.dailyTag.visit"),
        String(localized: "record.dailyTag.holiday"),
        String(localized: "record.dailyTag.dining"),
        String(localized: "record.dailyTag.callOn"),
        String(localized: "record.dailyTag.helpOut"),
        String(localized: "record.dailyTag.accompany"),
        String(localized: "record.dailyTag.lendReturn"),
    ]

    var allDailyTags: [String] {
        var tags = Self.builtInDailyTags
        for tag in customDailyTags where !tags.contains(tag) {
            tags.append(tag)
        }
        return tags
    }

    var allContacts: [Contact] = []
    var allEvents: [Event] = []

    var filteredContacts: [Contact] {
        if contactSearchText.isEmpty {
            return allContacts
        }
        return allContacts.filter { $0.name.localizedCaseInsensitiveContains(contactSearchText) }
    }

    var isValid: Bool {
        let hasContact = selectedContact != nil
        let hasEvent = selectedEvent != nil
        guard hasContact else { return false }
        if contextSelection == .event && !hasEvent {
            return false
        }
        switch recordType {
        case .monetary:  return (UserEnteredDecimal.parse(monetaryAmount) ?? 0) > 0
        case .gift:      return !giftName.trimmingCharacters(in: .whitespaces).isEmpty
        case .favor:     return !favorDesc.trimmingCharacters(in: .whitespaces).isEmpty
        case .banquet:   return !banquetLocation.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    var directionLabel: String {
        directionTitle(for: direction)
    }

    var confirmButtonTitle: String {
        switch (recordType, direction) {
        case (.monetary, .given): return String(localized: "record.confirm.monetary.given")
        case (.monetary, .received): return String(localized: "record.confirm.monetary.received")
        case (.gift, .given): return String(localized: "record.confirm.gift.given")
        case (.gift, .received): return String(localized: "record.confirm.gift.received")
        case (.favor, .given): return String(localized: "record.confirm.favor.given")
        case (.favor, .received): return String(localized: "record.confirm.favor.received")
        case (.banquet, .given): return String(localized: "record.confirm.banquet.given")
        case (.banquet, .received): return String(localized: "record.confirm.banquet.received")
        }
    }

    var navigationTitle: String {
        direction == .given
            ? String(localized: "record.add.titleGiven")
            : String(localized: "record.add.titleReceived")
    }

    func directionTitle(for direction: RecordDirection) -> String {
        switch (recordType, direction) {
        case (.monetary, .given): return String(localized: "record.direction.monetary.given")
        case (.monetary, .received): return String(localized: "record.direction.monetary.received")
        case (.gift, .given): return String(localized: "record.direction.gift.given")
        case (.gift, .received): return String(localized: "record.direction.gift.received")
        case (.favor, .given): return String(localized: "record.direction.favor.given")
        case (.favor, .received): return String(localized: "record.direction.favor.received")
        case (.banquet, .given): return String(localized: "record.direction.banquet.given")
        case (.banquet, .received): return String(localized: "record.direction.banquet.received")
        }
    }

    func loadData(context: ModelContext) {
        do {
            let contactDescriptor = FetchDescriptor<Contact>(
                sortBy: [SortDescriptor(\.name)]
            )
            allContacts = try context.fetch(contactDescriptor)

            let eventDescriptor = FetchDescriptor<Event>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            allEvents = try context.fetch(eventDescriptor)

            // 加载已有记录中的自定义标签（仅拉取 contextTag 非空的行，避免全表扫描）
            var tagDescriptor = FetchDescriptor<Record>(
                predicate: #Predicate<Record> { !$0.contextTag.isEmpty }
            )
            tagDescriptor.propertiesToFetch = [\.contextTag]
            let tagRecords = try context.fetch(tagDescriptor)
            let existingTags = Set(tagRecords.map(\.contextTag))
            customDailyTags = existingTags.filter { !Self.builtInDailyTags.contains($0) }.sorted()
        } catch {
            allContacts = []
            allEvents = []
        }
    }

    func addCustomTag() {
        let trimmed = customTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !customDailyTags.contains(trimmed) && !Self.builtInDailyTags.contains(trimmed) {
            customDailyTags.append(trimmed)
        }
        selectedDailyTag = trimmed
        customTagInput = ""
        isCreatingCustomTag = false
    }

    func configure(direction: RecordDirection?, contactID: PersistentIdentifier?, context: ModelContext) {
        if let dir = direction {
            self.direction = dir
        }
        if let cID = contactID {
            self.selectedContact = context.model(for: cID) as? Contact
        }
    }

    func configure(with record: Record) {
        editingRecord = record
        direction = record.direction
        selectedContact = record.contact
        selectedEvent = record.event
        contextSelection = record.event == nil ? .daily : .event
        selectedDailyTag = record.contextTag
        date = record.date
        note = record.note
        recordType = record.recordType
        relationshipWeight = record.relationshipWeight

        switch record.resolvedTypeData {
        case .monetary(let d):
            monetaryAmount = d.amount == Double(Int(d.amount)) ? String(Int(d.amount)) : String(d.amount)
            monetaryPaymentMethod = PaymentMethod(rawValue: d.paymentMethod) ?? .cash
        case .gift(let d):
            giftName = d.giftName
            if let v = d.estimatedValue {
                giftEstimatedValue = v == Double(Int(v)) ? String(Int(v)) : String(v)
            } else {
                giftEstimatedValue = ""
            }
        case .favor(let d):
            favorDesc = d.description
        case .banquet(let d):
            banquetLocation = d.location
            banquetAttendeeList = d.attendeeList
            banquetExtraCostNotes = d.extraCostNotes
        }
    }

    func buildTypeData() -> RecordTypeData {
        switch recordType {
        case .monetary:
            let amtStr = monetaryAmount.trimmingCharacters(in: .whitespacesAndNewlines)
            let returned = editingRecord?.resolvedReturnedAmount ?? 0
            return .monetary(MonetaryData(
                amount: UserEnteredDecimal.parse(amtStr) ?? 0,
                paymentMethod: monetaryPaymentMethod.rawValue,
                returnedAmount: returned
            ))
        case .gift:
            let name = giftName.trimmingCharacters(in: .whitespacesAndNewlines)
            let estStr = giftEstimatedValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let est: Double? = estStr.isEmpty ? nil : UserEnteredDecimal.parse(estStr)
            return .gift(GiftData(giftName: name, estimatedValue: est))
        case .favor:
            let desc = favorDesc.trimmingCharacters(in: .whitespacesAndNewlines)
            return .favor(FavorData(description: desc))
        case .banquet:
            return .banquet(BanquetData(
                location: banquetLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                attendeeList: banquetAttendeeList.trimmingCharacters(in: .whitespacesAndNewlines),
                extraCostNotes: banquetExtraCostNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }
    }

    private func resolveContact(context _: ModelContext) -> Contact? {
        selectedContact
    }

    private func resolveEvent(context: ModelContext) -> Event? {
        guard contextSelection == .event else {
            return nil
        }
        return selectedEvent
    }

    func save(context: ModelContext) -> Bool {
        guard isValid,
              let contact = resolveContact(context: context) else { return false }

        let event = resolveEvent(context: context)

        let typeData = buildTypeData()

        let resolvedTag = contextSelection == .daily ? selectedDailyTag : ""

        if let existing = editingRecord {
            existing.contact = contact
            existing.event = event
            existing.direction = direction
            existing.note = note
            existing.date = date
            existing.recordType = recordType
            existing.relationshipWeight = relationshipWeight
            existing.contextTag = resolvedTag
            existing.applyTypeData(typeData)

            for item in newPhotoItems {
                let photo = RecordPhoto(record: existing, imageData: item.data)
                context.insert(photo)
            }
            newPhotoItems = []

            do {
                try context.save()
                NotificationManager.shared.cancelReturnGiftReminder(record: existing)
                if existing.isMonetary, existing.direction == .given, !existing.hasReturnedGift {
                    NotificationManager.shared.scheduleReturnGiftReminder(record: existing)
                }
                return true
            } catch {
                return false
            }
        } else {
            let record = Record(
                contact: contact,
                event: event,
                direction: direction,
                note: note,
                date: date,
                recordType: recordType,
                relationshipWeight: relationshipWeight
            )
            record.contextTag = resolvedTag
            record.applyTypeData(typeData)

            context.insert(record)

            for item in newPhotoItems {
                let photo = RecordPhoto(record: record, imageData: item.data)
                context.insert(photo)
            }
            newPhotoItems = []

            do {
                try context.save()
                if record.isMonetary, record.direction == .given, !record.hasReturnedGift {
                    NotificationManager.shared.scheduleReturnGiftReminder(record: record)
                }
                return true
            } catch {
                return false
            }
        }
    }
}
