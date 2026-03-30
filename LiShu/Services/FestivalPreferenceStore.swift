import Foundation
import SwiftData

struct FestivalPreferenceStore {
    func preference(
        for festivalID: String,
        in preferences: [FestivalReminderPreference]
    ) -> FestivalReminderPreference? {
        preferences.first { $0.festivalID == festivalID }
    }

    @discardableResult
    func upsertPreference(
        festivalID: String,
        preferences: [FestivalReminderPreference],
        context: ModelContext,
        isReminderEnabled: Bool,
        useDefaultRecipients: Bool,
        recipientContactIDs: [String]
    ) -> FestivalReminderPreference {
        if let existing = preference(for: festivalID, in: preferences) {
            existing.isReminderEnabled = isReminderEnabled
            existing.useDefaultRecipients = useDefaultRecipients
            existing.recipientContactIDs = recipientContactIDs
            existing.updatedAt = .now
            return existing
        }

        let created = FestivalReminderPreference(
            festivalID: festivalID,
            isReminderEnabled: isReminderEnabled,
            useDefaultRecipients: useDefaultRecipients,
            recipientContactIDs: recipientContactIDs
        )
        context.insert(created)
        return created
    }
}
