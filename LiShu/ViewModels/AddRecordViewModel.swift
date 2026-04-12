import Foundation
import Logging
import SwiftData

private let recordsViewModelLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.recordsViewModel)

/// 待保存的新增照片（稳定 `id` 供 `ForEach` 使用）
struct NewRecordPhotoItem: Identifiable, Equatable {
    let id: UUID
    let data: Data

    static func == (lhs: NewRecordPhotoItem, rhs: NewRecordPhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum RecordContextSelection: String, CaseIterable {
    case event
    case daily
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
        let hasDailyTag = !selectedDailyTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard hasContact else { return false }
        if contextSelection == .event, !hasEvent {
            return false
        }
        if contextSelection == .daily, !hasDailyTag {
            return false
        }
        switch recordType {
        case .monetary: return (UserEnteredDecimal.parse(monetaryAmount) ?? 0) > 0
        case .gift: return !giftName.trimmingCharacters(in: .whitespaces).isEmpty
        case .favor: return !favorDesc.trimmingCharacters(in: .whitespaces).isEmpty
        case .banquet: return !banquetLocation.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    var directionLabel: String {
        directionTitle(for: direction)
    }

    var confirmButtonTitle: String {
        switch (recordType, direction) {
        case (.monetary, .given): String(localized: "record.confirm.monetary.given")
        case (.monetary, .received): String(localized: "record.confirm.monetary.received")
        case (.gift, .given): String(localized: "record.confirm.gift.given")
        case (.gift, .received): String(localized: "record.confirm.gift.received")
        case (.favor, .given): String(localized: "record.confirm.favor.given")
        case (.favor, .received): String(localized: "record.confirm.favor.received")
        case (.banquet, .given): String(localized: "record.confirm.banquet.given")
        case (.banquet, .received): String(localized: "record.confirm.banquet.received")
        }
    }

    var navigationTitle: String {
        String(localized: "record.add.navTitle")
    }

    /// 只要当前记录挂在事件下面，方向就由事件身份唯一决定，不再允许用户自由切换。
    var isDirectionLockedBySelectedEvent: Bool {
        contextSelection == .event && selectedEvent != nil
    }

    func directionTitle(for direction: RecordDirection) -> String {
        switch (recordType, direction) {
        case (.monetary, .given): String(localized: "record.direction.monetary.given")
        case (.monetary, .received): String(localized: "record.direction.monetary.received")
        case (.gift, .given): String(localized: "record.direction.gift.given")
        case (.gift, .received): String(localized: "record.direction.gift.received")
        case (.favor, .given): String(localized: "record.direction.favor.given")
        case (.favor, .received): String(localized: "record.direction.favor.received")
        case (.banquet, .given): String(localized: "record.direction.banquet.given")
        case (.banquet, .received): String(localized: "record.direction.banquet.received")
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
            recordsViewModelLogger.info("Loaded add record dependencies", metadata: [
                "step": .string("load_data"),
                "count": .stringConvertible(allContacts.count + allEvents.count),
                "result": .string("success"),
            ])
        } catch {
            allContacts = []
            allEvents = []
            recordsViewModelLogger.error("Failed to load add record dependencies", metadata: [
                "step": .string("load_data"),
                "error": .string(error.localizedDescription),
            ])
        }
    }

    func addCustomTag() {
        let trimmed = customTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !customDailyTags.contains(trimmed), !Self.builtInDailyTags.contains(trimmed) {
            customDailyTags.append(trimmed)
        }
        selectedDailyTag = trimmed
        customTagInput = ""
        isCreatingCustomTag = false
    }

    func configure(direction: RecordDirection?, contactID: PersistentIdentifier?, eventID: PersistentIdentifier?, context: ModelContext) {
        if let dir = direction {
            self.direction = dir
        }
        if let cID = contactID {
            selectedContact = context.model(for: cID) as? Contact
        }
        if let eventID {
            selectEvent(context.model(for: eventID) as? Event)
        }
        applyDirectionConstraintForSelectedEvent()
        recordsViewModelLogger.info("Configured add record context", metadata: [
            "step": .string("configure"),
            "contact_id": .string(contactID.map { String(describing: $0) } ?? "none"),
            "event_id": .string(eventID.map { String(describing: $0) } ?? "none"),
            "result": .string(direction?.rawValue ?? "unchanged"),
        ])
    }

    func configure(with record: Record) {
        recordsViewModelLogger.info("Configured record editor", metadata: [
            "step": .string("configure"),
            "record_id": .string(String(describing: record.persistentModelID)),
        ])
        editingRecord = record
        direction = record.direction
        selectedContact = record.contact
        contextSelection = record.event == nil ? .daily : .event
        selectedEvent = record.event
        applyDirectionConstraintForSelectedEvent()
        selectedDailyTag = record.contextTag
        date = record.date
        note = record.note
        recordType = record.recordType
        relationshipWeight = record.relationshipWeight

        switch record.resolvedTypeData {
        case let .monetary(d):
            monetaryAmount = d.amount == Double(Int(d.amount)) ? String(Int(d.amount)) : String(d.amount)
            monetaryPaymentMethod = PaymentMethod(rawValue: d.paymentMethod) ?? .cash
        case let .gift(d):
            giftName = d.giftName
            if let v = d.estimatedValue {
                giftEstimatedValue = v == Double(Int(v)) ? String(Int(v)) : String(v)
            } else {
                giftEstimatedValue = ""
            }
        case let .favor(d):
            favorDesc = d.description
        case let .banquet(d):
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

    private func resolveEvent(context _: ModelContext) -> Event? {
        guard contextSelection == .event else {
            return nil
        }
        return selectedEvent
    }

    /// 统一从这里切换事件，避免界面层直接赋值后漏掉方向约束同步。
    func selectEvent(_ event: Event?) {
        selectedEvent = event
        if event != nil {
            contextSelection = .event
        }
        applyDirectionConstraintForSelectedEvent()
    }

    /// 事件往来和日常往来切换时，要同步刷新方向，防止残留上一次事件带来的方向状态。
    func setContextSelection(_ selection: RecordContextSelection) {
        contextSelection = selection
        applyDirectionConstraintForSelectedEvent()
    }

    /// 业务约束：
    /// 1. 自己办的事件只能记“收到”
    /// 2. 参加别人的事件只能记“送出”
    /// 这样可以避免同一事件下出现与业务语义相反的记录方向。
    func applyDirectionConstraintForSelectedEvent() {
        guard contextSelection == .event, let event = selectedEvent else { return }
        direction = event.hostMode == .host ? .received : .given
    }

    private func buildDraftPayload(
        contact: Contact,
        event: Event?,
        direction: RecordDirection,
        typeData: RecordTypeData,
        contextTag: String
    ) -> RecordLogPayload {
        RecordLogPayload(
            id: editingRecord.map { String(describing: $0.persistentModelID) } ?? "pending",
            direction: direction.rawValue,
            recordType: recordType.rawValue,
            date: date,
            note: note,
            contact: contact.logPayload(),
            event: event?.logPayload(),
            contextSelection: contextSelection.rawValue,
            contextTag: contextTag,
            typeData: typeData.logPayload(),
            photoCount: (editingRecord?.photos?.count ?? 0) + newPhotoItems.count,
            relationshipWeight: relationshipWeight.rawValue
        )
    }

    private func compressedPhotoData(from data: Data) -> Data {
        ImagePipeline.optimizedJPEGData(
            from: data,
            maxPixelSize: ImagePipeline.Preset.recordPhotoMaxPixelSize,
            compressionQuality: 0.84
        ) ?? data
    }

    @MainActor
    func save(context: ModelContext) -> Bool {
        guard isValid,
              let contact = resolveContact(context: context)
        else {
            recordsViewModelLogger.warning("Rejected record save", metadata: [
                "step": .string("save"),
                "reason": .string("validation_failed"),
            ])
            return false
        }

        let event = resolveEvent(context: context)
        // 保存前再次按事件身份兜底纠正方向，避免界面状态遗漏造成脏数据。
        let resolvedDirection = resolvedDirection(for: event)
        direction = resolvedDirection

        let typeData = buildTypeData()

        let resolvedTag = contextSelection == .daily ? selectedDailyTag : ""
        let submissionPayload = buildDraftPayload(
            contact: contact,
            event: event,
            direction: resolvedDirection,
            typeData: typeData,
            contextTag: resolvedTag
        )

        if let existing = editingRecord {
            BusinessDataLogger.recordMutation(
                screen: "records.form",
                operation: "update_attempt",
                payload: submissionPayload
            )
            existing.contact = contact
            existing.event = event
            existing.direction = resolvedDirection
            existing.note = note
            existing.date = date
            existing.recordType = recordType
            existing.relationshipWeight = relationshipWeight
            existing.contextTag = resolvedTag
            existing.applyTypeData(typeData)

            for item in newPhotoItems {
                let photo = RecordPhoto(record: existing, imageData: compressedPhotoData(from: item.data))
                context.insert(photo)
            }
            newPhotoItems = []

            do {
                try context.save()
                NotificationManager.shared.cancelReturnGiftReminder(record: existing)
                if existing.isMonetary, existing.direction == .given, !existing.hasReturnedGift {
                    NotificationManager.shared.scheduleReturnGiftReminder(record: existing)
                }
                BusinessDataLogger.recordMutation(
                    screen: "records.form",
                    operation: "update",
                    payload: submissionPayload,
                    results: [existing.logPayload()]
                )
                recordsViewModelLogger.notice("Saved record", metadata: [
                    "step": .string("save"),
                    "record_id": .string(String(describing: existing.persistentModelID)),
                    "contact_id": .string(String(describing: contact.persistentModelID)),
                    "result": .string("updated"),
                ])
                return true
            } catch {
                BusinessDataLogger.recordMutation(
                    screen: "records.form",
                    operation: "update_failed",
                    payload: submissionPayload,
                    error: error.localizedDescription
                )
                recordsViewModelLogger.error("Failed to save record", metadata: [
                    "step": .string("save"),
                    "result": .string("updated"),
                    "error": .string(error.localizedDescription),
                ])
                return false
            }
        } else {
            BusinessDataLogger.recordMutation(
                screen: "records.form",
                operation: "create_attempt",
                payload: submissionPayload
            )
            let record = Record(
                contact: contact,
                event: event,
                direction: resolvedDirection,
                note: note,
                date: date,
                recordType: recordType,
                relationshipWeight: relationshipWeight
            )
            record.contextTag = resolvedTag
            record.applyTypeData(typeData)

            context.insert(record)

            for item in newPhotoItems {
                let photo = RecordPhoto(record: record, imageData: compressedPhotoData(from: item.data))
                context.insert(photo)
            }
            newPhotoItems = []

            do {
                try context.save()
                if record.isMonetary, record.direction == .given, !record.hasReturnedGift {
                    NotificationManager.shared.scheduleReturnGiftReminder(record: record)
                }
                BusinessDataLogger.recordMutation(
                    screen: "records.form",
                    operation: "create",
                    payload: submissionPayload,
                    results: [record.logPayload()]
                )
                recordsViewModelLogger.notice("Saved record", metadata: [
                    "step": .string("save"),
                    "record_id": .string(String(describing: record.persistentModelID)),
                    "contact_id": .string(String(describing: contact.persistentModelID)),
                    "result": .string("created"),
                ])
                return true
            } catch {
                BusinessDataLogger.recordMutation(
                    screen: "records.form",
                    operation: "create_failed",
                    payload: submissionPayload,
                    error: error.localizedDescription
                )
                recordsViewModelLogger.error("Failed to save record", metadata: [
                    "step": .string("save"),
                    "result": .string("created"),
                    "error": .string(error.localizedDescription),
                ])
                return false
            }
        }
    }

    func resetForContinuousEntry() {
        let preservedEvent = selectedEvent
        let preservedDirection = resolvedDirection(for: preservedEvent)
        let preservedPaymentMethod = monetaryPaymentMethod
        let preservedDate = Calendar.current.startOfDay(for: date)

        selectedContact = nil
        selectedEvent = preservedEvent
        contextSelection = preservedEvent == nil ? .daily : .event
        note = ""
        date = preservedDate
        newPhotoItems = []
        recordType = .monetary
        relationshipWeight = .reciprocal
        monetaryAmount = ""
        monetaryPaymentMethod = preservedPaymentMethod
        giftName = ""
        giftEstimatedValue = ""
        favorDesc = ""
        banquetLocation = ""
        banquetAttendeeList = ""
        banquetExtraCostNotes = ""
        direction = preservedDirection
    }

    /// 事件相关记录的方向由事件身份推导；只有脱离事件时才保留用户当前选择。
    private func resolvedDirection(for event: Event?) -> RecordDirection {
        guard contextSelection == .event, let event else { return direction }
        return event.hostMode == .host ? .received : .given
    }
}
