import Foundation
@testable import LiShu
import Testing

@MainActor
struct ExportPreviewViewModelTests {
    @Test func selectAllOnlySelectsExportableRows() {
        let viewModel = ExportPreviewViewModel(previewResult: ExportPreviewResult(
            recordType: .monetary,
            items: [
                ExportPreviewItem(
                    rowNumber: 2,
                    isSelected: true,
                    contactName: "张三",
                    contextText: "婚礼",
                    detailText: "2026-04-09 · 送出 · 金额",
                    trailingText: "¥800",
                    status: .ready,
                    payload: ExportPayload(rowValues: ["姓名": .string("张三"), "事件": .string("婚礼"), "金额": .number(800.00)])
                ),
                ExportPreviewItem(
                    rowNumber: 3,
                    isSelected: false,
                    contactName: "李四",
                    contextText: String(localized: "record.context.daily"),
                    detailText: "2026-04-09 · 送出 · 金额",
                    trailingText: "¥300",
                    status: .skipped(String(localized: "csv.export.preview.invalid.missingContext")),
                    payload: nil
                ),
            ],
            skipped: 1
        ))

        viewModel.deselectAll()
        #expect(viewModel.selectedCount == 0)
        #expect(viewModel.canExport == false)

        viewModel.selectAll()
        #expect(viewModel.selectedCount == 1)
        #expect(viewModel.isAllSelectableSelected == true)
        #expect(viewModel.items[1].isSelected == false)
    }

    @Test func exportingDisablesFurtherSelectionAndConfirm() {
        let viewModel = ExportPreviewViewModel(previewResult: ExportPreviewResult(
            recordType: .monetary,
            items: [
                ExportPreviewItem(
                    rowNumber: 2,
                    isSelected: true,
                    contactName: "张三",
                    contextText: "婚礼",
                    detailText: "2026-04-09 · 送出 · 金额",
                    trailingText: "¥800",
                    status: .ready,
                    payload: ExportPayload(rowValues: ["姓名": .string("张三")])
                ),
            ]
        ))

        #expect(viewModel.canExport == true)

        viewModel.isExporting = true
        viewModel.deselectAll()

        #expect(viewModel.canExport == false)
        #expect(viewModel.items[0].isSelected == true)
    }
}
