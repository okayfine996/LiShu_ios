import Foundation

// MARK: - Previews

extension WidgetSnapshot {
    static let preview = WidgetSnapshot(
        generatedAt: .now,
        reminders: [
            WidgetReminderItem(
                id: "prev-1",
                title: "王芳",
                subtitle: "生日",
                dateLabel: "明天",
                urgencyDaysFromNow: 1,
                kind: .birthday,
                deepLinkURL: URL(string: "lishu://contact?id=1")!,
                eventDateLabel: nil
            ),
            WidgetReminderItem(
                id: "prev-2",
                title: "婚礼酒席",
                subtitle: "婚礼",
                dateLabel: "3天后",
                urgencyDaysFromNow: 3,
                kind: .event,
                deepLinkURL: URL(string: "lishu://event?id=2")!,
                eventDateLabel: "1月4日"
            ),
            WidgetReminderItem(
                id: "prev-3",
                title: "朋友婚宴",
                subtitle: "待回礼",
                dateLabel: "今天",
                urgencyDaysFromNow: 0,
                kind: .pendingReturn,
                deepLinkURL: URL(string: "lishu://add-record?event=3&direction=given")!,
                eventDateLabel: nil
            ),
        ],
        reminderCount: 3,
        yearlyIncome: 12800,
        yearlyExpense: 8600,
        currentYear: 2026,
        nextHostingEvent: WidgetHostingEventItem(
            name: "我的婚礼",
            typeName: "婚礼",
            daysUntil: 7,
            dateLine: "1月8日 · 上海静安瑞吉",
            deepLinkURL: URL(string: "lishu://event?id=10")!,
            giftReceivedTotal: 45600,
            guestCount: 128,
            addRecordURL: URL(string: "lishu://add-record?event=10")!
        ),
        yearlyRecordCount: 42,
        yearlyContactCount: 18,
        pendingReturnCount: 2
    )
}
