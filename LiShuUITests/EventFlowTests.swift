import XCTest

final class EventFlowTests: BaseUITestCase {
    @MainActor
    func testAddEventFlow() {
        createEvent(name: "UI测试事件")

        let eventText = app.staticTexts["UI测试事件"]
        XCTAssertTrue(eventText.waitForExistence(timeout: 5), "New event should appear in list")
    }

    @MainActor
    func testEventListDisplay() {
        let eventsTab = app.tabBars.buttons[TabLabels.events]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()
        sleep(1)

        let navTitle = app.navigationBars.firstMatch
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3), "Events navigation bar should exist")
    }

    @MainActor
    func testEventDetail() {
        createEvent(name: "详情事件")

        let eventsTab = app.tabBars.buttons[TabLabels.events]
        eventsTab.tap()
        sleep(1)

        let eventCell = app.staticTexts["详情事件"]
        XCTAssertTrue(eventCell.waitForExistence(timeout: 5))
        eventCell.tap()
        sleep(1)

        let detailText = app.staticTexts["详情事件"]
        XCTAssertTrue(detailText.waitForExistence(timeout: 5), "Event detail should show the event name")
    }

    @MainActor
    func testDeleteEvent() {
        createEvent(name: "待删事件")

        let eventsTab = app.tabBars.buttons[TabLabels.events]
        eventsTab.tap()
        sleep(1)

        let eventCell = app.staticTexts["待删事件"]
        XCTAssertTrue(eventCell.waitForExistence(timeout: 5))
        eventCell.tap()
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
    func testEventListSwipeDeleteShowsCascadeMessage() {
        let contactName = "左滑事件联系人"
        let eventName = "左滑事件"

        createContact(name: contactName)
        createEvent(name: eventName)
        createMonetaryRecord(contactName: contactName, eventName: eventName, amount: "888")

        let eventsTab = app.tabBars.buttons[TabLabels.events]
        eventsTab.tap()
        sleep(1)

        let eventText = app.staticTexts[eventName].firstMatch
        XCTAssertTrue(eventText.waitForExistence(timeout: 5), "Created event should appear in list")
        eventText.swipeLeft()

        let deleteButton = app.buttons["删除"].firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Swipe delete button should appear")
        deleteButton.tap()

        let message = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] '1 条往来' AND label CONTAINS[c] '0 张照片'")
        ).firstMatch
        XCTAssertTrue(message.waitForExistence(timeout: 3), "Cascade delete message should describe linked records and photos")

        let confirmButton = app.alerts.buttons["删除"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 3), "Delete confirmation should appear")
        confirmButton.tap()

        XCTAssertFalse(app.staticTexts[eventName].waitForExistence(timeout: 3), "Deleted event should disappear from list")
    }
}
