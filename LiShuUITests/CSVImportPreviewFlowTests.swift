import XCTest

final class CSVImportPreviewFlowTests: BaseUITestCase {
    override func configureApplicationBeforeLaunch() throws {
        if name.contains("testCSVPreviewSupportsSelectAllAndConfirmImport") {
            app.launchEnvironment["UITEST_CSV_PREVIEW_CONTENT"] = Self.previewFixture
            app.launchEnvironment["UITEST_CSV_PREVIEW_FILENAME"] = "ui-preview.csv"
        }
        if name.contains("testCSVImportProcessingPreventsLeavingPreview") {
            app.launchEnvironment["UITEST_CSV_PREVIEW_CONTENT"] = Self.previewFixture
            app.launchEnvironment["UITEST_CSV_PREVIEW_FILENAME"] = "ui-preview.csv"
            app.launchEnvironment["UITEST_CSV_IMPORT_DELAY_MS"] = "3000"
        }
        if name.contains("testCSVImportRowTriggersFilePickerRequest") {
            app.launchEnvironment["UITEST_SKIP_SYSTEM_CSV_IMPORTER"] = "1"
        }
    }

    @MainActor
    func testCSVPreviewSupportsSelectAllAndConfirmImport() {
        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        sleep(1)

        let dataRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '数据' OR label CONTAINS[c] '导入' OR label CONTAINS[c] '导出'")
        ).firstMatch
        XCTAssertTrue(dataRow.waitForExistence(timeout: 3))
        dataRow.tap()

        let selectAllButton = app.buttons["csv.import.preview.selectAllButton"]
        XCTAssertTrue(selectAllButton.waitForExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts["张三"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["李四"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["王五"].waitForExistence(timeout: 2))

        let confirmButton = app.buttons["csv.import.preview.confirmButton"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 2))
        XCTAssertTrue(confirmButton.isEnabled)

        selectAllButton.tap()
        XCTAssertFalse(confirmButton.isEnabled)

        selectAllButton.tap()
        XCTAssertTrue(confirmButton.isEnabled)

        confirmButton.tap()

        let toast = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '导入完成：成功 2 条，跳过 1 条，失败 0 条'")
        ).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5))
        XCTAssertFalse(confirmButton.exists)
    }

    @MainActor
    func testCSVImportRowRemainsInteractiveWhenRequestingFilePicker() {
        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        sleep(1)

        let dataRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '数据' OR label CONTAINS[c] '导入' OR label CONTAINS[c] '导出'")
        ).firstMatch
        XCTAssertTrue(dataRow.waitForExistence(timeout: 3))
        dataRow.tap()

        let importCSVRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '导入 CSV' OR label CONTAINS[c] 'Import CSV'")
        ).firstMatch
        XCTAssertTrue(importCSVRow.waitForExistence(timeout: 3))
        importCSVRow.tap()

        let downloadTemplateRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '下载导入模板' OR label CONTAINS[c] 'Download Template'")
        ).firstMatch
        XCTAssertTrue(downloadTemplateRow.waitForExistence(timeout: 2), app.debugDescription)
    }

    @MainActor
    func testCSVImportProcessingPreventsLeavingPreview() {
        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        sleep(1)

        let dataRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '数据' OR label CONTAINS[c] '导入' OR label CONTAINS[c] '导出'")
        ).firstMatch
        XCTAssertTrue(dataRow.waitForExistence(timeout: 3))
        dataRow.tap()

        let confirmButton = app.buttons["csv.import.preview.confirmButton"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))

        let backButton = app.buttons["csv.import.preview.backButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 2), app.debugDescription)
        let previewTitle = app.navigationBars["导入预览"]
        XCTAssertTrue(previewTitle.waitForExistence(timeout: 2), app.debugDescription)

        confirmButton.tap()

        usleep(300_000)
        XCTAssertTrue(previewTitle.exists, app.debugDescription)
        XCTAssertTrue(confirmButton.exists, app.debugDescription)
        XCTAssertFalse(confirmButton.isEnabled, app.debugDescription)
        XCTAssertTrue(app.staticTexts["张三"].exists, app.debugDescription)
        if backButton.exists, backButton.isHittable {
            backButton.tap()
            XCTAssertTrue(previewTitle.waitForExistence(timeout: 1), app.debugDescription)
        }

        let toast = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '导入完成：成功 2 条，跳过 1 条，失败 0 条'")
        ).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 10), app.debugDescription)
    }
}

private extension CSVImportPreviewFlowTests {
    static let previewFixture = """
    联系人,事件,事件类型,场景标签,方向,日期,备注,金额,支付方式,已退金额
    张三,婚礼,婚礼,,送出,2026-04-09 10:30,婚礼礼金,800.00,微信,0.00
    李四,,,节日看望,送出,2026-04-09 10:30,日常往来,300.00,现金,0.00
    王五,,,,送出,2026-04-09 10:30,无上下文,200.00,现金,0.00
    """
}
