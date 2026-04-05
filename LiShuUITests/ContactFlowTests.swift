import XCTest

final class ContactFlowTests: BaseUITestCase {
    @MainActor
    func testContactListSearch() {
        createContact(name: "搜索测试人")

        let contactsTab = app.tabBars.buttons[TabLabels.contacts]
        contactsTab.tap()
        sleep(1)

        let contactText = app.staticTexts["搜索测试人"]
        XCTAssertTrue(contactText.waitForExistence(timeout: 5), "Created contact should appear in list")
    }

    @MainActor
    func testContactDetail() {
        createContact(name: "详情测试人")

        let contactsTab = app.tabBars.buttons[TabLabels.contacts]
        contactsTab.tap()
        sleep(1)

        let contactCell = app.staticTexts["详情测试人"]
        XCTAssertTrue(contactCell.waitForExistence(timeout: 5))
        contactCell.tap()
        sleep(1)

        let detailTitle = app.staticTexts["详情测试人"]
        XCTAssertTrue(detailTitle.waitForExistence(timeout: 5), "Contact detail should show the contact name")
    }

    @MainActor
    func testEditContact() {
        createContact(name: "编辑前名字")

        let contactsTab = app.tabBars.buttons[TabLabels.contacts]
        contactsTab.tap()
        sleep(1)

        let contactCell = app.staticTexts["编辑前名字"]
        XCTAssertTrue(contactCell.waitForExistence(timeout: 5))
        contactCell.tap()
        sleep(1)

        let editButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '编辑' OR label CONTAINS[c] 'pencil'")
        ).firstMatch
        if editButton.waitForExistence(timeout: 3) {
            editButton.tap()
            sleep(1)

            let nameField = app.textFields["contact.add.nameField"]
            if nameField.waitForExistence(timeout: 3) {
                nameField.tap()
                nameField.clearAndTypeText("编辑后名字")

                let saveButton = app.buttons["contact.add.saveButton"]
                if saveButton.waitForExistence(timeout: 3) {
                    saveButton.tap()
                    sleep(1)
                }
            }
        }
    }

    @MainActor
    func testDeleteContact() {
        createContact(name: "待删联系人")

        let contactsTab = app.tabBars.buttons[TabLabels.contacts]
        contactsTab.tap()
        sleep(1)

        let contactCell = app.staticTexts["待删联系人"]
        XCTAssertTrue(contactCell.waitForExistence(timeout: 5))
        contactCell.tap()
        sleep(1)

        let deleteButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '删除'")
        ).firstMatch
        if deleteButton.waitForExistence(timeout: 3) {
            deleteButton.tap()
            sleep(1)

            let confirmButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] '确认' OR label CONTAINS[c] '删除'")
            ).firstMatch
            if confirmButton.waitForExistence(timeout: 3) {
                confirmButton.tap()
                sleep(1)
            }
        }
    }

    @MainActor
    func testContactListNavigationBar() {
        let contactsTab = app.tabBars.buttons[TabLabels.contacts]
        XCTAssertTrue(contactsTab.waitForExistence(timeout: 5))
        contactsTab.tap()
        sleep(1)

        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Contacts navigation bar should exist")
    }
}

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = value as? String else {
            typeText(text)
            return
        }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
        typeText(text)
    }
}
