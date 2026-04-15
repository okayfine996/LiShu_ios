//
//  UITestConstants.swift
//  LiShuUITests
//
//  Tab labels matching Localizable.xcstrings (zh-Hans).
//  Update when localization changes.
//

import Foundation

enum TabLabels {
    static let home = "首页"
    static let records = "人情"
    static let contacts = "人脉"
    static let events = "事件"
    static let settings = "设置"
}

/// 与 `Localizable.xcstrings` zh-Hans 一致；文案变更时请同步
enum UITestStrings {
    /// `contact.add.title`
    static let newContactMenuItem = "新建联系人"
    /// `home.addRecord`
    static let addRecordMenuItem = "记一笔"
}
