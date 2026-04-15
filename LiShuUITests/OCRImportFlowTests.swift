import XCTest

final class OCRImportFlowTests: BaseUITestCase {
    override var defaultLaunchArguments: [String] {
        ["--uitesting", "--uitest-open-ocr"]
    }

    override var defaultLaunchEnvironment: [String: String] {
        let payload = [
            "测试礼金|108|108|国庆晚宴|high||appleAIEnhanced",
            "晚礼金测试|216|216|元旦聚会|medium|needsVerification|ledgerHeuristicFallback",
        ].joined(separator: ";")
        return [
            "UITEST_OCR_PREVIEW_ITEMS": payload,
            "UITEST_OCR_RECOGNITION_MODE": "ledgerHeuristicFallback",
            "UITEST_OCR_FILTERED_NOISE_COUNT": "2",
        ]
    }

    @MainActor
    func testOCRDeleteConfirmShownAndCanCancel() {
        let firstItem = "测试礼金"

        let firstItemText = app.staticTexts[firstItem]
        XCTAssertTrue(firstItemText.waitForExistence(timeout: 5), "OCR fixture items should appear in result list")

        let deleteButton = app.buttons["ocr.result.deleteButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Delete action should be available")
        deleteButton.tap()

        let confirmMessage = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] '识别记录' AND label CONTAINS[c] '2'")
        ).firstMatch
        XCTAssertTrue(confirmMessage.waitForExistence(timeout: 3), "Delete confirmation should show item count")

        let cancelButton = app.alerts.buttons["取消"]
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

        let deleteButton = app.buttons["ocr.result.deleteButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Delete action should be available")
        deleteButton.tap()

        let confirmButton = app.alerts.buttons["删除"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 3), "Confirmation delete button should be available")
        confirmButton.tap()

        XCTAssertFalse(
            app.staticTexts[firstItem].waitForExistence(timeout: 3),
            "Confirmed deletion should remove OCR rows"
        )
    }

    @MainActor
    func testOCRResultShowsRecognitionModeAndReviewIndicators() {
        XCTAssertTrue(app.staticTexts["本地礼簿规则兜底"].waitForExistence(timeout: 5), "Recognition mode badge should be visible")
        XCTAssertTrue(app.staticTexts["以下有 1 条记录需要人工确认"].waitForExistence(timeout: 3), "Review banner should show correct count")
        XCTAssertTrue(app.staticTexts["已过滤噪声 2 条"].waitForExistence(timeout: 3), "Filtered noise badge should be visible")
        XCTAssertTrue(app.staticTexts["请核对"].waitForExistence(timeout: 3), "Warning text should be visible for low-confidence items")
    }
}
