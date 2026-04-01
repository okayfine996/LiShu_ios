//
//  SnapshotHelper.swift
//  LiShuUITests
//
//  Generated for fastlane snapshot support.
//

import Foundation
import XCTest

func setupSnapshot(_ app: XCUIApplication) {
    Snapshot.setupSnapshot(app)
}

func snapshot(_ name: String, waitForLoadingIndicator: Bool = true) {
    Snapshot.snapshot(name, waitForLoadingIndicator: waitForLoadingIndicator)
}

private enum Snapshot {
    static var app: XCUIApplication?
    static var regexes: [NSRegularExpression] = []

    static func snapshot(_ name: String, waitForLoadingIndicator: Bool) {
        if app == nil {
            setupSnapshot(XCUIApplication())
        }

        guard let app else { return }

        if waitForLoadingIndicator {
            waitForLoadingIndicatorToDisappear(in: app)
        }

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = sanitize(name)
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "Snapshot: \(name)") { activity in
            activity.add(attachment)
        }
    }

    static func setupSnapshot(_ app: XCUIApplication) {
        Snapshot.app = app
        app.launchArguments += setupSnapshotLaunchArguments()
    }

    static func setupSnapshotLaunchArguments() -> [String] {
        [
            "-FASTLANE_SNAPSHOT",
            "YES",
            "-FASTLANE_SNAPSHOT_DIR",
            ProcessInfo.processInfo.environment["FASTLANE_SNAPSHOT_DIR"] ?? ""
        ]
    }

    static func sanitize(_ name: String) -> String {
        if regexes.isEmpty {
            regexes = [
                try! NSRegularExpression(pattern: "[^a-zA-Z0-9_\\-]", options: []),
                try! NSRegularExpression(pattern: "\\-+", options: [])
            ]
        }

        var sanitized = name.replacingOccurrences(of: " ", with: "-")
        regexes.forEach { regex in
            sanitized = regex.stringByReplacingMatches(
                in: sanitized,
                options: [],
                range: NSRange(location: 0, length: sanitized.count),
                withTemplate: "-"
            )
        }
        return sanitized
    }

    static func waitForLoadingIndicatorToDisappear(in app: XCUIApplication) {
        let predicate = NSPredicate(format: "exists == false")
        let element = app.otherElements["In progress"]
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        _ = XCTWaiter.wait(for: [expectation], timeout: 30.0)
    }
}
