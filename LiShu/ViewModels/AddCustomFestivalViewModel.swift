import Foundation
import SwiftData

@Observable
class AddCustomFestivalViewModel {
    var name: String = ""
    var calendarType: FestivalCalendarType = .lunar
    var month: Int = 1
    var day: Int = 1
    var isReminderEnabled: Bool = true
    var useDefaultRecipients: Bool = true
    var selectedContactIDs: Set<String> = []
    var showValidationAlert: Bool = false

    var monthRange: ClosedRange<Int> {
        1...12
    }

    var dayRange: ClosedRange<Int> {
        calendarType == .solar ? 1...31 : 1...30
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && monthRange.contains(month)
            && dayRange.contains(day)
    }

    func save(
        context: ModelContext,
        preferences: [FestivalReminderPreference]
    ) -> Bool {
        guard isValid else {
            showValidationAlert = true
            return false
        }

        let customFestival = CustomFestival(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            calendarType: calendarType,
            month: month,
            day: day,
            isEnabled: isReminderEnabled
        )
        context.insert(customFestival)

        FestivalPreferenceStore().upsertPreference(
            festivalID: customFestival.identifier,
            preferences: preferences,
            context: context,
            isReminderEnabled: isReminderEnabled,
            useDefaultRecipients: useDefaultRecipients,
            recipientContactIDs: Array(selectedContactIDs).sorted()
        )

        do {
            try context.save()
            NotificationManager.shared.rescheduleAll(context: context)
            return true
        } catch {
            return false
        }
    }
}
