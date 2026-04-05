#if DEBUG
    import Foundation
    import Logging
    import SwiftData

    private let debugDataLogger = PulseDiagnostics.makeLogger(label: "debug.data")

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
                debugDataLogger.error("Failed to clear debug sample data", metadata: [
                    "error": .string(String(describing: error)),
                ])
            }
        }
    }
#endif
