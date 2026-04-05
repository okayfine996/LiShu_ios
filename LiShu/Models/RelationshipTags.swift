import Foundation

enum RelationshipCategory: String, CaseIterable, Identifiable, Codable {
    case family = "家人"
    case relative = "亲戚"
    case social = "社会"

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .family: "figure.2.and.child.holdinghands"
        case .relative: "person.2"
        case .social: "building.2"
        }
    }

    var circle: Int {
        switch self {
        case .family: 1
        case .relative: 2
        case .social: 3
        }
    }

    var tags: [String] {
        switch self {
        case .family:
            ["父亲", "母亲", "配偶", "儿子", "女儿", "兄弟", "姐妹"]
        case .relative:
            [
                "祖父", "祖母", "外公", "外婆",
                "伯父", "叔叔", "姑姑", "舅舅", "姨妈",
                "堂兄弟", "堂姐妹", "表兄弟", "表姐妹",
                "侄子", "侄女", "外甥", "外甥女",
                "公公", "婆婆", "岳父", "岳母",
                "大伯", "小叔", "弟媳", "嫂子",
            ]
        case .social:
            [
                "同事", "同学", "朋友", "邻居", "同乡",
                "生意伙伴", "客户", "上级", "下属",
                "发小", "战友", "师傅", "徒弟",
            ]
        }
    }
}
