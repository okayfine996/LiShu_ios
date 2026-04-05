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
        case .recordDetail: "records.detail"
        case .addRecord: "records.add"
        case .monthlyDetail: "statistics.monthlyDetail"
        case .periodDetail: "statistics.periodDetail"
        case .contactExchange: "contacts.exchange"
        case .contactDetail: "contacts.detail"
        case .addContact: "contacts.add"
        case .eventList: "events.list"
        case .eventDetail: "events.detail"
        case .addEvent: "events.add"
        case .statistics: "statistics.home"
        case .eventTypeComposition: "statistics.eventTypeComposition"
        case .netValueRanking: "statistics.netValueRanking"
        case .circleDetail: "statistics.circleDetail"
        case .recordTypeComposition: "statistics.recordTypeComposition"
        case .heatmapDetail: "statistics.heatmapDetail"
        case .proMembership: "settings.proMembership"
        case .appearanceSettings: "settings.appearance"
        case .notificationSettings: "settings.notifications"
        case .dataManagement, .importExport: "settings.dataManagement"
        case .about: "settings.about"
        case .termsOfService: "settings.terms"
        case .privacyPolicy: "settings.privacy"
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
        case .addRecord: "addRecord"
        case .addContact: "addContact"
        case .addEvent: "addEvent"
        case let .editContact(id): "editContact-\(id)"
        case let .editEvent(id): "editEvent-\(id)"
        case let .editRecord(id): "editRecord-\(id)"
        case .returnGift: "returnGift"
        case .ocrImport: "ocrImport"
        case .proMembership: "proMembership"
        }
    }

    var logName: String {
        switch self {
        case .addRecord: "sheet.records.add"
        case .addContact: "sheet.contacts.add"
        case .addEvent: "sheet.events.add"
        case .editContact: "sheet.contacts.edit"
        case .editEvent: "sheet.events.edit"
        case .editRecord: "sheet.records.edit"
        case .returnGift: "sheet.records.returnGift"
        case .ocrImport: "sheet.import.ocr"
        case .proMembership: "sheet.settings.proMembership"
        }
    }
}
