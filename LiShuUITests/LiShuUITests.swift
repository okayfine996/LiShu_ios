//
//  LiShuUITests.swift
//  LiShuUITests
//
//  Created by Fine Ke on 1/3/2026.
//

import XCTest

final class LiShuUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        // Wait for splash screen to finish
        sleep(2)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Add Contact Flow

    @MainActor
    func testAddContactFlow() {
        // 1. Navigate to Contacts tab
        let contactsTab = app.tabBars.buttons["人脉"]
        XCTAssertTrue(contactsTab.waitForExistence(timeout: 5))
        contactsTab.tap()

        // 2. Tap the "+" add button in the toolbar
        // Since it's a NavigationLink, we look for it by identifier or by the plus icon
        let addButton = app.navigationBars.buttons.matching(identifier: "contact.list.addButton").firstMatch
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            let menuAdd = app.buttons[UITestStrings.newContactMenuItem].firstMatch
            if menuAdd.waitForExistence(timeout: 2) {
                menuAdd.tap()
            }
        } else {
            let navPlus = app.navigationBars.buttons["plus"]
            if navPlus.waitForExistence(timeout: 3) {
                navPlus.tap()
                Thread.sleep(forTimeInterval: 0.5)
                let menuAdd = app.buttons[UITestStrings.newContactMenuItem].firstMatch
                if menuAdd.waitForExistence(timeout: 2) {
                    menuAdd.tap()
                }
            }
        }

        // 3. Wait for AddContactView to appear
        sleep(1)

        // 4. Type the contact name
        let nameField = app.textFields["contact.add.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Name field should exist")
        nameField.tap()
        nameField.typeText("UI测试联系人")

        // 5. Tap save button
        let saveButton = app.buttons["contact.add.saveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        saveButton.tap()

        // 6. Verify we're back on the contact list and the contact appears
        sleep(1)
        let contactText = app.staticTexts["UI测试联系人"]
        XCTAssertTrue(contactText.waitForExistence(timeout: 5), "New contact should appear in list")
    }

    // MARK: - Navigation Between Tabs

    @MainActor
    func testTabNavigation() {
        // Verify all tabs are accessible（与 Localizable zh-Hans / UITestConstants.TabLabels 一致）
        let tabs = [TabLabels.home, TabLabels.records, TabLabels.contacts, TabLabels.events, TabLabels.settings]
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.waitForExistence(timeout: 3), "Tab '\(tabName)' should exist")
            tab.tap()
            sleep(1) // Wait for tab content to load
        }
    }
}
