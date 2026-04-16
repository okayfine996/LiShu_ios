import SwiftData
import SwiftUI

#Preview {
    Group {
        if let container = try? ModelContainer(
            for: Contact.self, Record.self, Event.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ) {
            NavigationStack {
                AddEventView()
            }
            .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
