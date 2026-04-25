import SwiftUI

/// Defines the available guide flows for the app.
enum AppGuideFlow {
    /// 收礼引导：首页新建礼簿 → 登记收礼
    static func mainTour() -> [GuideStep] {
        [
            GuideStep(
                id: "guide.welcome",
                titleKey: "guide.welcome.title",
                bodyKey: "guide.welcome.body"
            ),
            GuideStep(
                id: "guide.shou.createLedger",
                titleKey: "guide.shou.createLedger.title",
                bodyKey: "guide.shou.createLedger.body",
                anchorID: "home.ledger.newButton",
                spotlightPadding: 12,
                completionTrigger: .eventCreated,
                isPassThrough: true,
                requiredTab: .home
            ),
            GuideStep(
                id: "guide.shou.addReceipt",
                titleKey: "guide.shou.addReceipt.title",
                bodyKey: "guide.shou.addReceipt.body",
                anchorID: "home.ledger.receiptButton",
                spotlightPadding: 8,
                completionTrigger: .recordCreated,
                isPassThrough: true,
                requiredTab: .home
            ),
            GuideStep(
                id: "guide.done",
                titleKey: "guide.done.title",
                bodyKey: "guide.done.body"
            ),
        ]
    }

    /// 随礼引导：记录 Tab → 点 + 按钮 → AddRecordView（direction 默认 .given）→ 保存
    static func suiLiTour() -> [GuideStep] {
        [
            GuideStep(
                id: "guide.sui.welcome",
                titleKey: "guide.sui.welcome.title",
                bodyKey: "guide.sui.welcome.body"
            ),
            GuideStep(
                id: "guide.sui.addRecord",
                titleKey: "guide.sui.addRecord.title",
                bodyKey: "guide.sui.addRecord.body",
                anchorID: "record.list.addButton",
                spotlightPadding: 14,
                completionTrigger: .recordCreated,
                isPassThrough: true,
                requiredTab: .records
            ),
            GuideStep(
                id: "guide.sui.done",
                titleKey: "guide.sui.done.title",
                bodyKey: "guide.sui.done.body"
            ),
        ]
    }
}
