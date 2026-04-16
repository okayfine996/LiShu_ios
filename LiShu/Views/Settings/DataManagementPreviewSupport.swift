import SwiftData
import SwiftUI

#Preview {
    NavigationStack {
        DataManagementView()
            .environment(SubscriptionManager.shared)
            .environment(DebugOverrideManager())
    }
    .modelContainer(for: [Contact.self, Record.self, Event.self], inMemory: true)
}
