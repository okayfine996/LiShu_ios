//
//  BaseUITestCase.swift
//  LiShuUITests
//
//  Base class for UI tests with common setup and helpers.
//

import XCTest

class BaseUITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
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
        } else {
            let navPlus = app.buttons["plus"].firstMatch
            if navPlus.waitForExistence(timeout: 3) {
                navPlus.tap()
            }
        }
        sleep(1)

        let nameField = app.textFields["contact.add.nameField"]
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
