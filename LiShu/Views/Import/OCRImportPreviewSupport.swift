import SwiftData
import SwiftUI

@MainActor
private func makeOCRImportPreviewContainer() -> ModelContainer? {
    guard let container = try? ModelContainer(
        for: Contact.self, Record.self, Event.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) else {
        return nil
    }

    let event = Event(name: "我的婚礼礼簿", type: .wedding, hostMode: .host, date: .now)
    container.mainContext.insert(event)
    return container
}

@MainActor
private func previewLedgerEventID(from container: ModelContainer) -> PersistentIdentifier {
    let descriptor = FetchDescriptor<Event>()
    if let event = try? container.mainContext.fetch(descriptor).first {
        return event.persistentModelID
    }

    let fallbackEvent = Event(name: "我的婚礼礼簿", type: .wedding, hostMode: .host, date: .now)
    container.mainContext.insert(fallbackEvent)
    return fallbackEvent.persistentModelID
}

struct OCRImportPreview: View {
    var body: some View {
        Group {
            if let container = makeOCRImportPreviewContainer() {
                OCRImportView(eventID: previewLedgerEventID(from: container))
                    .modelContainer(container)
            } else {
                Text(String(localized: "common.preview.unavailable"))
            }
        }
    }
}

@MainActor
struct OCRImportProcessingPreview: View {
    private let container: ModelContainer?
    private let eventID: PersistentIdentifier?
    private let viewModel: OCRImportViewModel?

    init(processingState: LoadingState<[OCRRecordItem]>, isAIEnhanced: Bool) {
        if let container = makeOCRImportPreviewContainer() {
            let eventID = previewLedgerEventID(from: container)
            let viewModel = OCRImportViewModel(eventID: eventID)
            viewModel.processingState = processingState
            viewModel.isAIEnhanced = isAIEnhanced

            self.container = container
            self.eventID = eventID
            self.viewModel = viewModel
        } else {
            container = nil
            eventID = nil
            viewModel = nil
        }
    }

    var body: some View {
        if let container, let eventID, let viewModel {
            OCRImportView(eventID: eventID, viewModel: viewModel)
                .modelContainer(container)
        } else {
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
