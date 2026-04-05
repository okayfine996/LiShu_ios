//
//  AppStoreScreenshotTests.swift
//  LiShuUITests
//
//  App Store 截图 UI 测试。setUp 顺序须与 fastlane 文档一致：
//  https://docs.fastlane.tools/getting-started/ios/screenshots/
//  （XCUIApplication → setupSnapshot → launch）
//

import XCTest

final class AppStoreScreenshotTests: XCTestCase {

    /// 须与主 App Target 的 `PRODUCT_BUNDLE_IDENTIFIER` 一致。命令行 `xcodebuild test`/snapshot 下无参 `XCUIApplication()` 可能误绑定为 UITest bundle，导致 launch 报 FBSApplicationLibrary nil。
    private static let hostAppBundleIdentifier = "com.finefine.LiShu"

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        app = XCUIApplication(bundleIdentifier: Self.hostAppBundleIdentifier)
        app.launchArguments = ["--uitesting"]
        // 与文档 Objective-C 示例一致，截图跑法可关动画等待以加快执行
        setupSnapshot(app, waitForAnimations: false)
        app.launch()

        XCTAssertTrue(
            app.tabBars.firstMatch.waitForExistence(timeout: 20),
            "主界面 Tab 应在启动后出现（含闪屏时间）。官方说明须用命令行跑 snapshot，勿仅在 Xcode 内点 Run。"
        )
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    func testCaptureAppStoreScreenshots() throws {
        captureHome()
        captureRecords()
        captureContacts()
        captureEvents()
        captureSettings()
    }

    private func captureHome() {
        tapTab(TabLabels.home)
        sleep(1)
        snapshot("01-首页-总览")
    }

    private func captureRecords() {
        tapTab(TabLabels.records)
        sleep(1)
        snapshot("02-人情-记录")
    }

    private func captureContacts() {
        tapTab(TabLabels.contacts)
        sleep(1)
        snapshot("03-人脉-管理")
    }

    private func captureEvents() {
        tapTab(TabLabels.events)
        sleep(1)
        snapshot("04-事件-场景")
    }

    private func captureSettings() {
        tapTab(TabLabels.settings)
        sleep(1)
        snapshot("05-设置-个人中心")
    }

    private func tapTab(_ label: String) {
        let button = app.tabBars.buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "应能找到 Tab：\(label)")
        button.tap()
    }
}
