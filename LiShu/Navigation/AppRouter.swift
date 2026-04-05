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
    case eventTypeComposition(year: Int)
    case netValueRanking(year: Int)
    case circleDetail(Int, year: Int)
    case recordTypeComposition(year: Int)
    case heatmapDetail(year: Int)
    // 设置子页
    case proMembership
    case appearanceSettings
    case notificationSettings
    case dataManagement
    case importExport
    case about
    case termsOfService
    case privacyPolicy

    var logName: String {
        switch self {
        case .recordDetail: return "records.detail"
        case .addRecord: return "records.add"
        case .monthlyDetail: return "statistics.monthlyDetail"
        case .periodDetail: return "statistics.periodDetail"
        case .contactExchange: return "contacts.exchange"
        case .contactDetail: return "contacts.detail"
        case .addContact: return "contacts.add"
        case .eventList: return "events.list"
        case .eventDetail: return "events.detail"
        case .addEvent: return "events.add"
        case .statistics: return "statistics.home"
        case .eventTypeComposition: return "statistics.eventTypeComposition"
        case .netValueRanking: return "statistics.netValueRanking"
        case .circleDetail: return "statistics.circleDetail"
        case .recordTypeComposition: return "statistics.recordTypeComposition"
        case .heatmapDetail: return "statistics.heatmapDetail"
        case .proMembership: return "settings.proMembership"
        case .appearanceSettings: return "settings.appearance"
        case .notificationSettings: return "settings.notifications"
        case .dataManagement, .importExport: return "settings.dataManagement"
        case .about: return "settings.about"
        case .termsOfService: return "settings.terms"
        case .privacyPolicy: return "settings.privacy"
        }
    }
}

enum SheetRoute: Identifiable, Equatable {
    case addRecord(direction: RecordDirection?, contactID: PersistentIdentifier?)
    case addContact
    case addEvent
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
        case let .editContact(id): return "editContact-\(id)"
        case let .editEvent(id): return "editEvent-\(id)"
        case let .editRecord(id): return "editRecord-\(id)"
        case .returnGift: return "returnGift"
        case .ocrImport: return "ocrImport"
        case .proMembership: return "proMembership"
        }
    }

    var logName: String {
        switch self {
        case .addRecord: return "sheet.records.add"
        case .addContact: return "sheet.contacts.add"
        case .addEvent: return "sheet.events.add"
        case .editContact: return "sheet.contacts.edit"
        case .editEvent: return "sheet.events.edit"
        case .editRecord: return "sheet.records.edit"
        case .returnGift: return "sheet.records.returnGift"
        case .ocrImport: return "sheet.import.ocr"
        case .proMembership: return "sheet.settings.proMembership"
        }
    }
}
