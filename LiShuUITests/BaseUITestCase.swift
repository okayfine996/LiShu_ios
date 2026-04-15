//
//  BaseUITestCase.swift
//  LiShuUITests
//
//  Base class for UI tests with common setup and helpers.
//

import XCTest

class BaseUITestCase: XCTestCase {
    var app: XCUIApplication!
    var defaultLaunchArguments: [String] {
        ["--uitesting"]
    }

    var defaultLaunchEnvironment: [String: String] {
        [:]
    }

    /// 子类可重写（如 App Store 截图）：在 `launch()` 前调用 `setupSnapshot(app)` 等。
    func configureApplicationBeforeLaunch() throws {}

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = defaultLaunchArguments
        app.launchEnvironment = defaultLaunchEnvironment
        try configureApplicationBeforeLaunch()
        app.launch()
        sleep(2)
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    @MainActor
    func createContact(name: String) {
        let contactsTab = app.tabBars.buttons[TabLabels.contacts]
        contactsTab.tap()
        sleep(1)

        let addButton = app.navigationBars.buttons.matching(identifier: "contact.list.addButton").firstMatch
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            // 工具栏为 Menu：先展开再选「新建联系人」
            let menuAdd = app.buttons[UITestStrings.newContactMenuItem].firstMatch
            if menuAdd.waitForExistence(timeout: 2) {
                menuAdd.tap()
            }
        } else {
            let navPlus = app.buttons["plus"].firstMatch
            if navPlus.waitForExistence(timeout: 3) {
                navPlus.tap()
                Thread.sleep(forTimeInterval: 0.5)
                let menuAdd = app.buttons[UITestStrings.newContactMenuItem].firstMatch
                if menuAdd.waitForExistence(timeout: 2) {
                    menuAdd.tap()
                }
            }
        }
        sleep(1)

        var nameField = app.textFields["contact.add.nameField"]
        if !nameField.waitForExistence(timeout: 3) {
            // 空列表时也可点空状态主按钮直接进入添加页
            let emptyAdd = app.buttons[UITestStrings.newContactMenuItem].firstMatch
            if emptyAdd.waitForExistence(timeout: 2) {
                emptyAdd.tap()
                sleep(1)
                nameField = app.textFields["contact.add.nameField"]
            }
        }
        if nameField.waitForExistence(timeout: 5) {
            nameField.tap()
            nameField.typeText(name)
        }

        let saveButton = app.buttons["contact.add.saveButton"]
        if saveButton.waitForExistence(timeout: 3) {
            saveButton.tap()
        }
        sleep(1)
    }

    @MainActor
    func createEvent(name: String) {
        let eventsTab = app.tabBars.buttons[TabLabels.events]
        eventsTab.tap()
        sleep(1)

        let addButton = app.buttons["event.list.addButton"].firstMatch
        let emptyActionButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '添加' OR label CONTAINS[c] '新增'")
        ).firstMatch

        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
        } else if emptyActionButton.waitForExistence(timeout: 3) {
            emptyActionButton.tap()
        }
        sleep(1)

        let nameField = app.textFields.firstMatch
        if nameField.waitForExistence(timeout: 5) {
            nameField.tap()
            nameField.typeText(name)
        }

        let saveButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '保存' OR label CONTAINS[c] '确认' OR label CONTAINS[c] '创建'")
        ).firstMatch
        if saveButton.waitForExistence(timeout: 3) {
            saveButton.tap()
        }
        sleep(1)
    }

    @MainActor
    func createMonetaryRecord(contactName: String, eventName: String, amount: String = "666") {
        let recordsTab = app.tabBars.buttons[TabLabels.records]
        recordsTab.tap()
        sleep(1)

        let addButton = app.buttons["record.list.addButton"].firstMatch
        let emptyActionButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '添加' OR label CONTAINS[c] '新增'")
        ).firstMatch

        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            let menuAddRecord = app.buttons[UITestStrings.addRecordMenuItem].firstMatch
            if menuAddRecord.waitForExistence(timeout: 2) {
                menuAddRecord.tap()
            }
        } else if emptyActionButton.waitForExistence(timeout: 3) {
            emptyActionButton.tap()
        }
        sleep(1)

        let contactSelector = app.otherElements["record.add.contactSelector"].firstMatch
        XCTAssertTrue(contactSelector.waitForExistence(timeout: 5), "Contact selector should exist in add record view")
        XCTAssertTrue(
            tapHorizontalSelectorItem(
                in: contactSelector,
                buttonIdentifier: "record.add.contact.\(contactName)",
                fallbackLabel: contactName
            ),
            "Contact selector should show \(contactName)"
        )

        XCTAssertTrue(
            tapEventSelectorItem(eventName: eventName),
            "Event selector should show \(eventName)"
        )

        let amountField = app.textFields["record.add.amountField"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 5), "Amount field should exist in add record view")
        amountField.tap()
        amountField.typeText(amount)

        let saveButton = app.buttons["record.add.saveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist in add record view")
        saveButton.tap()
        sleep(1)
    }

    @MainActor
    private func tapHorizontalSelectorItem(
        in selector: XCUIElement,
        buttonIdentifier: String,
        fallbackLabel: String,
        maxSwipes: Int = 8
    ) -> Bool {
        for _ in 0 ... maxSwipes {
            let button = selector.buttons[buttonIdentifier].firstMatch
            if button.exists, button.isHittable {
                button.tap()
                return true
            }

            let text = selector.staticTexts[fallbackLabel].firstMatch
            if text.exists, text.isHittable {
                text.tap()
                return true
            }

            selector.swipeLeft()
            Thread.sleep(forTimeInterval: 0.3)
        }

        return false
    }

    @MainActor
    private func tapEventSelectorItem(eventName: String) -> Bool {
        let buttonIdentifier = "record.add.event.\(eventName)"

        for _ in 0 ..< 4 {
            let selector = app.otherElements["record.add.eventSelector"].firstMatch
            if selector.exists,
               tapHorizontalSelectorItem(
                   in: selector,
                   buttonIdentifier: buttonIdentifier,
                   fallbackLabel: eventName,
                   maxSwipes: 4
               )
            {
                return true
            }

            let eventButton = app.buttons[buttonIdentifier].firstMatch
            if eventButton.exists, eventButton.isHittable {
                eventButton.tap()
                return true
            }

            let eventText = app.staticTexts[eventName].firstMatch
            if eventText.exists, eventText.isHittable {
                eventText.tap()
                return true
            }

            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.4)
        }

        return false
    }
}
