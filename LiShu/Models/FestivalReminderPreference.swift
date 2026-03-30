import Foundation
import SwiftData

@Model
final class FestivalReminderPreference {
    var festivalID: String = ""
    var isReminderEnabled: Bool = true
    var useDefaultRecipients: Bool = true
    var recipientContactIDsStorage: String = ""
    var updatedAt: Date = Foundation.Date(timeIntervalSince1970: 0)

    init(
        festivalID: String,
        isReminderEnabled: Bool = true,
        useDefaultRecipients: Bool = true,
        recipientContactIDs: [String] = []
    ) {
        self.festivalID = festivalID
        self.isReminderEnabled = isReminderEnabled
        self.useDefaultRecipients = useDefaultRecipients
        self.updatedAt = Foundation.Date.now
        self.recipientContactIDsStorage = recipientContactIDs.joined(separator: "|")
    }

    var recipientContactIDs: [String] {
        get {
            guard !recipientContactIDsStorage.isEmpty else { return [] }
            return recipientContactIDsStorage
                .split(separator: "|")
                .map(String.init)
        }
        set {
            recipientContactIDsStorage = newValue.joined(separator: "|")
        }
    }
}
