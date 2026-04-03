#if DEBUG
import Foundation
import SwiftData

@MainActor
enum DebugDataGenerator {

    static func generateSampleData(context: ModelContext) {
        DemoDataSeeding.insertSampleData(context: context, attachDemoMedia: true)
    }

    static func clearAllData(context: ModelContext) {
        do {
            try context.delete(model: Record.self)
            try context.delete(model: RecordPhoto.self)
            try context.delete(model: Event.self)
            try context.delete(model: Contact.self)
            try context.save()
        } catch {
            print("[DebugDataGenerator] clearAllData failed: \(error)")
        }
    }
}
#endif
