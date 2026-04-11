import Foundation
@testable import LiShu
import Testing

@MainActor
struct CSVImportPreviewViewModelTests {
    @Test func selectAllOnlySelectsImportableRows() {
        let viewModel = CSVImportPreviewViewModel(previewResult: CSVImportPreviewResult(
            sourceFileName: "preview.csv",
            items: [
                CSVImportPreviewItem(
                    rowNumber: 2,
                    isSelected: true,
                    contactName: "张三",
                    eventName: "婚礼",
                    eventTypeName: "婚礼",
                    sceneTag: "",
                    direction: .given,
                    date: .now,
                    dateText: "2026-04-09",
                    note: "",
                    recordType: .monetary,
                    contextText: "婚礼",
                    trailingText: "¥800",
                    detailText: "2026-04-09 · 送出 · 金额",
                    status: .ready,
                    payload: CSVImportPayload(
                        contactName: "张三",
                        eventName: "婚礼",
                        eventType: .wedding,
                        sceneTag: "",
                        direction: .given,
                        date: .now,
                        note: "",
                        recordType: .monetary,
                        relationshipWeight: .reciprocal,
                        returnedAmount: 0,
                        typeData: .monetary(MonetaryData(amount: 800, paymentMethod: PaymentMethod.cash.rawValue, returnedAmount: 0))
                    )
                ),
                CSVImportPreviewItem(
                    rowNumber: 3,
                    isSelected: false,
                    contactName: "李四",
                    eventName: "",
                    eventTypeName: "",
                    sceneTag: "",
                    direction: .given,
                    date: .now,
                    dateText: "2026-04-09",
                    note: "",
                    recordType: .gift,
                    contextText: "",
                    trailingText: "茶具",
                    detailText: "2026-04-09 · 送出 · 礼品",
                    status: .skipped(String(localized: "csv.import.preview.invalid.missingContext")),
                    payload: nil
                ),
            ],
            skipped: 1,
            errors: 0
        ))

        viewModel.deselectAll()
        #expect(viewModel.selectedCount == 0)
        #expect(viewModel.canImport == false)

        viewModel.selectAll()
        #expect(viewModel.selectedCount == 1)
        #expect(viewModel.isAllSelectableSelected == true)
        #expect(viewModel.items[1].isSelected == false)
    }

    @Test func importingDisablesFurtherSelectionAndConfirm() {
        let viewModel = CSVImportPreviewViewModel(previewResult: CSVImportPreviewResult(
            sourceFileName: "preview.csv",
            items: [
                CSVImportPreviewItem(
                    rowNumber: 2,
                    isSelected: true,
                    contactName: "张三",
                    eventName: "婚礼",
                    eventTypeName: "婚礼",
                    sceneTag: "",
                    direction: .given,
                    date: .now,
                    dateText: "2026-04-09",
                    note: "",
                    recordType: .monetary,
                    contextText: "婚礼",
                    trailingText: "¥800",
                    detailText: "2026-04-09 · 送出 · 金额",
                    status: .ready,
                    payload: CSVImportPayload(
                        contactName: "张三",
                        eventName: "婚礼",
                        eventType: .wedding,
                        sceneTag: "",
                        direction: .given,
                        date: .now,
                        note: "",
                        recordType: .monetary,
                        relationshipWeight: .reciprocal,
                        returnedAmount: 0,
                        typeData: .monetary(MonetaryData(amount: 800, paymentMethod: PaymentMethod.cash.rawValue, returnedAmount: 0))
                    )
                ),
            ]
        ))

        #expect(viewModel.canImport == true)

        viewModel.isImporting = true
        viewModel.deselectAll()

        #expect(viewModel.canImport == false)
        #expect(viewModel.items[0].isSelected == true)
    }
}
