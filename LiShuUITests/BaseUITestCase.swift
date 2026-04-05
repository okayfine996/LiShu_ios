//
//  BaseUITestCase.swift
//  LiShuUITests
//
//  Base class for UI tests with common setup and helpers.
//

import XCTest

class BaseUITestCase: XCTestCase {
    var app: XCUIApplication!
    var defaultLaunchArguments: [String] { ["--uitesting"] }

    /// 子类可重写（如 App Store 截图）：在 `launch()` 前调用 `setupSnapshot(app)` 等。
    func configureApplicationBeforeLaunch() throws {}

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = defaultLaunchArguments
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

        let addButton = app.buttons["plus"].firstMatch
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
}
