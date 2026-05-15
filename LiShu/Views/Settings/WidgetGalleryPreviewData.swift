import Foundation

enum WidgetGalleryPreviewData {
    static let liShuHome: URL = {
        var c = URLComponents(); c.scheme = "lishu"; c.host = "home"
        return c.url ?? URL(fileURLWithPath: "/")
    }()

    static let liShuGiveGift: URL = {
        var c = URLComponents()
        c.scheme = "lishu"; c.host = "add-record"
        c.queryItems = [URLQueryItem(name: "event", value: "1"), URLQueryItem(name: "direction", value: "given")]
        return c.url ?? URL(fileURLWithPath: "/")
    }()

    static let liShuAddRecord: URL = {
        var c = URLComponents()
        c.scheme = "lishu"; c.host = "add-record"
        c.queryItems = [URLQueryItem(name: "event", value: "gallery")]
        return c.url ?? URL(fileURLWithPath: "/")
    }()

    static let sampleSnapshot = WidgetSnapshot(
        generatedAt: .now,
        reminders: [
            WidgetReminderItem(
                id: "1", title: "回礼 · 林悦",
                subtitle: "满月宴", dateLabel: "今天",
                urgencyDaysFromNow: 0, kind: .pendingReturn,
                deepLinkURL: liShuGiveGift,
                eventDateLabel: "5月15日"
            ),
            WidgetReminderItem(
                id: "2", title: "何洁",
                subtitle: "生日", dateLabel: "明天",
                urgencyDaysFromNow: 1, kind: .birthday,
                deepLinkURL: liShuHome, eventDateLabel: "5月16日"
            ),
            WidgetReminderItem(
                id: "3", title: "表妹订婚",
                subtitle: "订婚宴", dateLabel: "后天",
                urgencyDaysFromNow: 2, kind: .event,
                deepLinkURL: liShuHome, eventDateLabel: "5月17日"
            ),
        ],
        reminderCount: 5,
        yearlyIncome: 44000,
        yearlyExpense: 12000,
        currentYear: Calendar.current.component(.year, from: .now),
        nextHostingEvent: WidgetHostingEventItem(
            name: "我的婚礼", typeName: "婚礼", daysUntil: 7,
            dateLine: "4月24日 · 上海静安瑞吉",
            deepLinkURL: liShuHome,
            giftReceivedTotal: 35700, guestCount: 16,
            addRecordURL: liShuAddRecord
        ),
        yearlyRecordCount: 147,
        yearlyContactCount: 38,
        pendingReturnCount: 4
    )
}

extension WidgetSnapshot {
    static let galleryPreview = WidgetGalleryPreviewData.sampleSnapshot
}
