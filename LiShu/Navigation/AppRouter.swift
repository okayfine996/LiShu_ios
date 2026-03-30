import Foundation
import SwiftData

enum AppRoute: Hashable {
    // 记录
    case recordDetail(PersistentIdentifier)
    case addRecord(direction: RecordDirection?, contactID: PersistentIdentifier?)
    case monthlyDetail(year: Int, month: Int)
    case periodDetail(StatsPeriod)
    // 联系人
    case contactExchange(PersistentIdentifier)
    case contactDetail(PersistentIdentifier)
    case addContact
    // 事件
    case eventList
    case eventDetail(PersistentIdentifier)
    case addEvent
    // 统计
    case statistics
    case eventTypeDetail(EventType, year: Int)
    case netValueRanking(year: Int)
    case circleDetail(Int, year: Int)
    // 设置子页
    case proMembership
    case appearanceSettings
    case notificationSettings
    case festivalManagement
    case addCustomFestival
    case festivalRecipientSettings(FestivalConfigurationRouteData)
    case dataManagement
    case importExport
    case about
    case termsOfService
    case privacyPolicy
}

enum SheetRoute: Identifiable, Equatable {
    case addRecord(direction: RecordDirection?, contactID: PersistentIdentifier?)
    case addContact
    case addEvent
    case addFestivalEvent(FestivalEventPrefill)
    case festivalReminderDetail(FestivalReminderRouteData)
    case editContact(PersistentIdentifier)
    case editEvent(PersistentIdentifier)
    case editRecord(PersistentIdentifier)
    case returnGift(recordID: PersistentIdentifier)
    case ocrImport
    case proMembership

    var id: String {
        switch self {
        case .addRecord: return "addRecord"
        case .addContact: return "addContact"
        case .addEvent: return "addEvent"
        case .addFestivalEvent(let prefill): return "addFestivalEvent-\(prefill.name)-\(prefill.date.timeIntervalSince1970)"
        case .festivalReminderDetail(let route): return "festivalReminderDetail-\(route.id)"
        case .editContact(let id): return "editContact-\(id)"
        case .editEvent(let id): return "editEvent-\(id)"
        case .editRecord(let id): return "editRecord-\(id)"
        case .returnGift: return "returnGift"
        case .ocrImport: return "ocrImport"
        case .proMembership: return "proMembership"
        }
    }
}
