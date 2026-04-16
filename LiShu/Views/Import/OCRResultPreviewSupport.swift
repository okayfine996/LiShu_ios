import SwiftData
import SwiftUI

struct OCRResultPreview: View {
    var body: some View {
        Group {
            if let container = makeOCRResultPreviewContainer() {
                let eventID = ocrResultPreviewEventID(from: container)
                OCRResultView(viewModel: {
                    let viewModel = OCRImportViewModel(eventID: eventID)
                    viewModel.items = [
                        OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
                        OCRRecordItem(
                            name: "李四",
                            amount: 200,
                            amountText: "200",
                            confidence: .medium,
                            warningType: .needsVerification
                        ),
                        OCRRecordItem(name: "王五", amount: 1000, amountText: "1,000", confidence: .high),
                        OCRRecordItem(name: "赵六", amount: 300, amountText: "300", confidence: .high),
                        OCRRecordItem(
                            name: "陈七",
                            amount: 5020,
                            amountText: "5,0?0",
                            confidence: .medium,
                            warningType: .suspiciousAmount
                        ),
                        OCRRecordItem(name: "周八", amount: 88, amountText: "88", confidence: .high),
                        OCRRecordItem(name: "吴九", amount: 1200, amountText: "1,200", confidence: .high),
                    ]
                    viewModel.processingState = .loaded(viewModel.items)
                    return viewModel
                }())
                    .modelContainer(container)
            } else {
                Text(String(localized: "common.preview.unavailable"))
            }
        }
    }
}

struct OCRResultAIEnhancedPreview: View {
    var body: some View {
        Group {
            if let container = makeOCRResultPreviewContainer() {
                let eventID = ocrResultPreviewEventID(from: container)
                OCRResultView(viewModel: {
                    let viewModel = OCRImportViewModel(eventID: eventID)
                    viewModel.items = [
                        OCRRecordItem(name: "张三", amount: 500, amountText: "500", confidence: .high),
                        OCRRecordItem(name: "李四", amount: 200, amountText: "200", confidence: .high),
                        OCRRecordItem(name: "王五", amount: 1000, amountText: "1,000", confidence: .high),
                    ]
                    viewModel.isAIEnhanced = true
                    viewModel.processingState = .loaded(viewModel.items)
                    return viewModel
                }())
                    .modelContainer(container)
            } else {
                Text(String(localized: "common.preview.unavailable"))
            }
        }
    }
}

@MainActor
private func makeOCRResultPreviewContainer() -> ModelContainer? {
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
private func ocrResultPreviewEventID(from container: ModelContainer) -> PersistentIdentifier {
    let descriptor = FetchDescriptor<Event>()
    if let event = try? container.mainContext.fetch(descriptor).first {
        return event.persistentModelID
    }

    let fallbackEvent = Event(name: "我的婚礼礼簿", type: .wedding, hostMode: .host, date: .now)
    container.mainContext.insert(fallbackEvent)
    return fallbackEvent.persistentModelID
}
