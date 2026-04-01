//
//  AppStoreScreenshotTests.swift
//  LiShuUITests
//
//  Dedicated UI tests for App Store screenshots.
//

import XCTest

final class AppStoreScreenshotTests: BaseUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        setupSnapshot(app)
    }

    @MainActor
    func testCaptureAppStoreScreenshots() throws {
        captureHome()
        captureRecords()
        captureContacts()
        captureEvents()
        captureSettings()
    }

    @MainActor
    private func captureHome() {
        app.tabBars.buttons[TabLabels.home].tap()
        sleep(1)
        snapshot("01-首页-总览")
    }

    @MainActor
    private func captureRecords() {
        app.tabBars.buttons[TabLabels.records].tap()
        sleep(1)
        snapshot("02-人情-记录")
    }

    @MainActor
    private func captureContacts() {
        app.tabBars.buttons[TabLabels.contacts].tap()
        sleep(1)
        snapshot("03-人脉-管理")
    }

    @MainActor
    private func captureEvents() {
        app.tabBars.buttons[TabLabels.events].tap()
        sleep(1)
        snapshot("04-事件-场景")
    }

    @MainActor
    private func captureSettings() {
        app.tabBars.buttons[TabLabels.settings].tap()
        sleep(1)
        snapshot("05-设置-个人中心")
    }
}
