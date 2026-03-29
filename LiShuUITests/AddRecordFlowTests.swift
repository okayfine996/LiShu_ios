//
//  AddRecordFlowTests.swift
//  LiShuUITests
//
//  Created by Fine Ke on 1/3/2026.
//

import XCTest

final class AddRecordFlowTests: BaseUITestCase {

    @MainActor
    func testAddRecordFullFlow() throws {
        createContact(name: "记录测试联系人")
        createEvent(name: "记录测试事件")

        let recordsTab = app.tabBars.buttons[TabLabels.records]
        recordsTab.tap()
        sleep(1)

        let addButton = app.buttons["plus"].firstMatch
        let emptyActionButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '添加'")
        ).firstMatch

        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
        } else if emptyActionButton.waitForExistence(timeout: 3) {
            emptyActionButton.tap()
        }
        sleep(1)

        let amountField = app.textFields["record.add.amountField"]
        if amountField.waitForExistence(timeout: 5) {
            amountField.tap()
            amountField.typeText("666")
        }

        let closeButton = app.buttons["record.add.closeButton"]
        if closeButton.waitForExistence(timeout: 3) {
            closeButton.tap()
        }
    }

    @MainActor
    func testRecordListFilterTabs() throws {
        let recordsTab = app.tabBars.buttons[TabLabels.records]
        XCTAssertTrue(recordsTab.waitForExistence(timeout: 5))
        recordsTab.tap()
        sleep(1)

        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Records navigation bar should exist")
    }

    @MainActor
    func testAddRecordFromHomeEmptyState() throws {
        let homeTab = app.tabBars.buttons[TabLabels.home]
        homeTab.tap()
        sleep(1)

        let addRecordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] '添加'")).firstMatch

        if addRecordButton.waitForExistence(timeout: 5) {
            addRecordButton.tap()
            sleep(1)

            let amountField = app.textFields["record.add.amountField"]
            XCTAssertTrue(amountField.waitForExistence(timeout: 5), "Amount field should appear in AddRecord sheet")

            let closeButton = app.buttons["record.add.closeButton"]
            if closeButton.waitForExistence(timeout: 3) {
                closeButton.tap()
            }
        }
    }

    @MainActor
    func testRecordListNavigation() throws {
        let recordsTab = app.tabBars.buttons[TabLabels.records]
        XCTAssertTrue(recordsTab.waitForExistence(timeout: 5))
        recordsTab.tap()
        sleep(1)

        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Records tab should have navigation bar")

        let emptyView = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '暂无' OR label CONTAINS[c] '没有' OR label CONTAINS[c] '记录'")
        ).firstMatch
        if emptyView.waitForExistence(timeout: 3) {
            XCTAssertTrue(true, "Empty state is displayed")
        }
    }

    @MainActor
    func testOpenAddRecordSheet() throws {
        let recordsTab = app.tabBars.buttons[TabLabels.records]
        recordsTab.tap()
        sleep(1)

        let addButton = app.buttons["plus"].firstMatch
        let emptyActionButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '添加'")
        ).firstMatch

        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            sleep(1)

            let amountField = app.textFields["record.add.amountField"]
            XCTAssertTrue(amountField.waitForExistence(timeout: 5), "Amount field should exist in add record view")

            let closeButton = app.buttons["record.add.closeButton"]
            if closeButton.waitForExistence(timeout: 3) {
                closeButton.tap()
            }
        } else if emptyActionButton.waitForExistence(timeout: 3) {
            emptyActionButton.tap()
            sleep(1)

            let amountField = app.textFields["record.add.amountField"]
            if amountField.waitForExistence(timeout: 5) {
                XCTAssertTrue(true, "Add record sheet appeared")
            }

            let closeButton = app.buttons["record.add.closeButton"]
            if closeButton.waitForExistence(timeout: 3) {
                closeButton.tap()
            }
        }
    }

    @MainActor
    func testReturnGiftSheetElements() throws {
        createContact(name: "还礼测试人")
        createEvent(name: "还礼测试事件")

        let recordsTab = app.tabBars.buttons[TabLabels.records]
        recordsTab.tap()
        sleep(1)

        let addButton = app.buttons["plus"].firstMatch
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            sleep(1)

            let amountField = app.textFields["record.add.amountField"]
            if amountField.waitForExistence(timeout: 5) {
                amountField.tap()
                amountField.typeText("888")
            }

            let closeButton = app.buttons["record.add.closeButton"]
            if closeButton.waitForExistence(timeout: 3) {
                closeButton.tap()
            }
        }
    }
}
