import XCTest

final class XLSXImportPreviewFlowTests: BaseUITestCase {
    override func configureApplicationBeforeLaunch() throws {
        if name.contains("testXLSXPreviewSupportsSelectAllAndConfirmImport") {
            app.launchEnvironment["UITEST_XLSX_PREVIEW_MOCK"] = "1"
        }
        if name.contains("testXLSXImportProcessingPreventsLeavingPreview") {
            app.launchEnvironment["UITEST_XLSX_PREVIEW_MOCK"] = "1"
            app.launchEnvironment["UITEST_XLSX_IMPORT_DELAY_MS"] = "3000"
        }
    }

    @MainActor
    func testXLSXPreviewSupportsSelectAllAndConfirmImport() {
        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        sleep(1)

        let dataRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '数据' OR label CONTAINS[c] '导入' OR label CONTAINS[c] '导出'")
        ).firstMatch
        XCTAssertTrue(dataRow.waitForExistence(timeout: 3))
        dataRow.tap()

        // Trigger mock XLSX preview
        let importXLSXRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '导入 XLSX' OR label CONTAINS[c] 'Import XLSX'")
        ).firstMatch
        XCTAssertTrue(importXLSXRow.waitForExistence(timeout: 3))
        importXLSXRow.tap()

        let selectAllButton = app.buttons["csv.import.preview.selectAllButton"]
        XCTAssertTrue(selectAllButton.waitForExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts["张三"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["李四"].waitForExistence(timeout: 2))

        let confirmButton = app.buttons["csv.import.preview.confirmButton"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 2))
        XCTAssertTrue(confirmButton.isEnabled)

        selectAllButton.tap() // Deselect all
        XCTAssertFalse(confirmButton.isEnabled)

        selectAllButton.tap() // Select all
        XCTAssertTrue(confirmButton.isEnabled)

        confirmButton.tap()

        let toast = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '导入完成'")
        ).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5))
        XCTAssertFalse(confirmButton.exists)
    }

    @MainActor
    func testXLSXImportProcessingPreventsLeavingPreview() {
        let settingsTab = app.tabBars.buttons[TabLabels.settings]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        sleep(1)

        let dataRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '数据' OR label CONTAINS[c] '导入' OR label CONTAINS[c] '导出'")
        ).firstMatch
        XCTAssertTrue(dataRow.waitForExistence(timeout: 3))
        dataRow.tap()

        let importXLSXRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '导入 XLSX' OR label CONTAINS[c] 'Import XLSX'")
        ).firstMatch
        XCTAssertTrue(importXLSXRow.waitForExistence(timeout: 3))
        importXLSXRow.tap()

        let confirmButton = app.buttons["csv.import.preview.confirmButton"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))

        let backButton = app.buttons["xlsx.import.preview.backButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 2))

        confirmButton.tap()

        // During processing, back button should be disabled or not responsive
        usleep(300_000)
        XCTAssertTrue(confirmButton.exists)
        XCTAssertFalse(confirmButton.isEnabled)

        if backButton.exists, backButton.isHittable {
            backButton.tap()
            // Should still be on preview screen
            XCTAssertTrue(confirmButton.exists)
        }

        let toast = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '导入完成'")
        ).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 10))
    }
}
