import SwiftData
import SwiftUI

#Preview {
    NavigationStack {
        ContactListView()
    }
    .modelContainer(for: Contact.self, inMemory: true)
}
