import XCTest

final class EventFlowTests: BaseUITestCase {

    @MainActor
    func testAddEventFlow() throws {
        createEvent(name: "UI测试事件")

        let eventText = app.staticTexts["UI测试事件"]
        XCTAssertTrue(eventText.waitForExistence(timeout: 5), "New event should appear in list")
    }

    @MainActor
    func testEventListDisplay() throws {
        let eventsTab = app.tabBars.buttons[TabLabels.events]
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5))
        eventsTab.tap()
        sleep(1)

        let navTitle = app.navigationBars.firstMatch
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3), "Events navigation bar should exist")
    }

    @MainActor
    func testEventDetail() throws {
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
    func testDeleteEvent() throws {
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
    func testFestivalCardCanOpenFestivalDetailThenCreateEvent() throws {
        let homeTab = app.tabBars.buttons[TabLabels.home]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        homeTab.tap()

        let festivalCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "home.festivalCard.")
        ).firstMatch
        XCTAssertTrue(festivalCard.waitForExistence(timeout: 5), "Festival card should appear on home")
        festivalCard.tap()

        let createEventButton = app.buttons["发起节日事件"]
        XCTAssertTrue(createEventButton.waitForExistence(timeout: 5), "Festival detail should open from home card")
        createEventButton.tap()

        let nameField = app.textFields["event.add.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Add event sheet should open from festival detail")

        let value = nameField.value as? String
        XCTAssertNotNil(value)
        XCTAssertFalse((value ?? "").isEmpty, "Festival event name should be prefilled")
    }
}
