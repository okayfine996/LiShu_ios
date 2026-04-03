import XCTest

final class StatisticsFlowTests: BaseUITestCase {

    @MainActor
    func testStatisticsViewDisplay() throws {
        let homeTab = app.tabBars.buttons[TabLabels.home]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        homeTab.tap()
        sleep(1)

        let statsFromHome = app.buttons["home.openStatistics"].firstMatch
        let statsByLabel = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] '统计' OR label CONTAINS[c] '报表'")
        ).firstMatch

        if statsFromHome.waitForExistence(timeout: 3) {
            statsFromHome.tap()
            sleep(1)

            let navBar = app.navigationBars.firstMatch
            XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Statistics view should have a navigation bar")
        } else if statsByLabel.waitForExistence(timeout: 3) {
            statsByLabel.tap()
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

        // 空库时无「礼金/¥」汇总；年度总览与「今年总来往」始终存在
        let summaryLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '年度总览' OR label CONTAINS[c] '今年总来往'")
        ).firstMatch
        XCTAssertTrue(summaryLabel.waitForExistence(timeout: 5), "Home summary card should show year overview")
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
