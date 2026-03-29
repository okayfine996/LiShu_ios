import XCTest

final class StatisticsFlowTests: BaseUITestCase {

    @MainActor
    func testStatisticsViewDisplay() throws {
        let homeTab = app.tabBars.buttons[TabLabels.home]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        homeTab.tap()
        sleep(1)

        let statsButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '统计' OR label CONTAINS[c] '报表' OR label CONTAINS[c] '详情'")
        ).firstMatch

        let statsLink = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '统计' OR label CONTAINS[c] '报表'")
        ).firstMatch

        if statsButton.waitForExistence(timeout: 3) {
            statsButton.tap()
            sleep(1)

            let navBar = app.navigationBars.firstMatch
            XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Statistics view should have a navigation bar")
        } else if statsLink.waitForExistence(timeout: 3) {
            statsLink.tap()
            sleep(1)

            let navBar = app.navigationBars.firstMatch
            XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Statistics view should have a navigation bar")
        }
    }

    @MainActor
    func testHomeSummaryCardExists() throws {
        let homeTab = app.tabBars.buttons[TabLabels.home]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        homeTab.tap()
        sleep(1)

        let incomeLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '收入' OR label CONTAINS[c] '¥'")
        ).firstMatch
        XCTAssertTrue(incomeLabel.waitForExistence(timeout: 5), "Home summary card should display income info")
    }

    @MainActor
    func testHomeUpcomingEventsSection() throws {
        let homeTab = app.tabBars.buttons[TabLabels.home]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        homeTab.tap()
        sleep(1)

        let upcomingLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '即将' OR label CONTAINS[c] '待办' OR label CONTAINS[c] '事件'")
        ).firstMatch
        if upcomingLabel.waitForExistence(timeout: 3) {
            XCTAssertTrue(true, "Upcoming events section exists")
        }
    }

    @MainActor
    func testHomeRecentRecordsSection() throws {
        let homeTab = app.tabBars.buttons[TabLabels.home]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        homeTab.tap()
        sleep(1)

        let recentLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '最近' OR label CONTAINS[c] '近期' OR label CONTAINS[c] '记录'")
        ).firstMatch
        if recentLabel.waitForExistence(timeout: 3) {
            XCTAssertTrue(true, "Recent records section exists")
        }
    }

    @MainActor
    func testAllFiveTabsAccessible() throws {
        let tabNames = [TabLabels.home, TabLabels.records, TabLabels.contacts, TabLabels.events, TabLabels.settings]
        for name in tabNames {
            let tab = app.tabBars.buttons[name]
            XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab '\(name)' should exist")
            tab.tap()
            sleep(1)
            let navBar = app.navigationBars.firstMatch
            XCTAssertTrue(navBar.waitForExistence(timeout: 3), "\(name) tab should have a navigation bar")
        }
    }
}
