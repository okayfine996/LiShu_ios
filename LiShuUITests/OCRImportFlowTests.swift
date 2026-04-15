import XCTest

final class OCRImportFlowTests: BaseUITestCase {
    override var defaultLaunchArguments: [String] {
        ["--uitesting", "--uitest-open-ocr"]
    }

    override var defaultLaunchEnvironment: [String: String] {
        let payload = [
            "测试礼金|108|108|国庆晚宴",
            "晚礼金测试|216|216|元旦聚会",
        ].joined(separator: ";")
        return ["UITEST_OCR_PREVIEW_ITEMS": payload]
    }

    @MainActor
    func testOCRDeleteConfirmShownAndCanCancel() {
        let firstItem = "测试礼金"

        let firstItemText = app.staticTexts[firstItem]
        XCTAssertTrue(firstItemText.waitForExistence(timeout: 5), "OCR fixture items should appear in result list")

        let selectAllButton = app.buttons["ocr.result.selectAllButton"]
        XCTAssertTrue(selectAllButton.waitForExistence(timeout: 3), "Select-all button should exist")
        selectAllButton.tap()

        let deleteButton = app.buttons["ocr.result.deleteButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Delete action should be available")
        deleteButton.tap()

        let confirmMessage = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] '识别记录' AND label CONTAINS[c] '2'")
        ).firstMatch
        XCTAssertTrue(confirmMessage.waitForExistence(timeout: 3), "Delete confirmation should show item count")

        let cancelButton = app.buttons["ocr.delete.cancelButton"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3), "Cancel should be available in confirmation")
        cancelButton.tap()

        XCTAssertTrue(
            firstItemText.waitForExistence(timeout: 3),
            "Cancel should keep OCR records unchanged"
        )
    }

    @MainActor
    func testOCRDeleteConfirmAndDeleteRemovesItems() {
        let firstItem = "测试礼金"

        let selectAllButton = app.buttons["ocr.result.selectAllButton"]
        XCTAssertTrue(selectAllButton.waitForExistence(timeout: 3), "Select-all button should exist")
        selectAllButton.tap()

        let deleteButton = app.buttons["ocr.result.deleteButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Delete action should be available")
        deleteButton.tap()

        let confirmButton = app.buttons["ocr.delete.confirmButton"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 3), "Confirmation delete button should be available")
        confirmButton.tap()

        XCTAssertFalse(
            app.staticTexts[firstItem].waitForExistence(timeout: 3),
            "Confirmed deletion should remove OCR rows"
        )
    }
}
