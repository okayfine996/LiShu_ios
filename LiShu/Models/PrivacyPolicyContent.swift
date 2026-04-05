import Foundation

struct PrivacyPolicyContent: Decodable {
    let updateDate: String
    let version: String
    let title: String
    let intro: String
    let sections: [PolicySection]

    struct PolicySection: Decodable, Identifiable {
        var id: String {
            title
        }

        let title: String
        let content: String
    }

    static func load() -> PrivacyPolicyContent? {
        guard let url = Bundle.main.url(forResource: "privacy_policy", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PrivacyPolicyContent.self, from: data)
    }
}
