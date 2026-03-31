import Foundation
import SwiftData
import UIKit

@Observable
class OCRImportViewModel {

    // MARK: - Image Management

    var capturedImages: [UIImage] = []
    var isShowingCamera = false
    var isShowingPhotoPicker = false
    var isShowingSourcePicker = false

    // MARK: - OCR State

    var processingState: LoadingState<[OCRRecordItem]> = .idle
    var items: [OCRRecordItem] = []

    // MARK: - AI Enhancement

    var isAIEnhanced = false

    // MARK: - Import Config

    var direction: RecordDirection = .given
    var isShowingImportConfig = false
    var isImporting = false
    var importSuccess = false
    var importError: String?

    // MARK: - Correction Sheet

    var editingItem: OCRRecordItem?
    var editName: String = ""
    var editAmountText: String = ""
    var editDate: Date = .now
    var editEventName: String = ""

    // MARK: - Computed

    var selectedItems: [OCRRecordItem] {
        items.filter(\.isSelected)
    }

    var selectedCount: Int {
        selectedItems.count
    }

    var lowConfidenceCount: Int {
        items.filter { $0.confidence == .low || $0.confidence == .medium }.count
    }

    var isAllSelected: Bool {
        !items.isEmpty && items.allSatisfy(\.isSelected)
    }

    var canImport: Bool {
        !selectedItems.isEmpty
    }

    // MARK: - Image Actions

    func addImage(_ image: UIImage) {
        capturedImages.append(image)
    }

    func clearImages() {
        capturedImages.removeAll()
        items.removeAll()
        processingState = .idle
        isAIEnhanced = false
    }

    // MARK: - OCR Processing

    func processImages() async {
        guard !capturedImages.isEmpty else { return }

        await MainActor.run {
            processingState = .loading
            if #available(iOS 26.0, *) {
                isAIEnhanced = AIAnalysisService.shared.isAvailable
            }
        }

        do {
            let result = try await OCRService.shared.recognizeRecordsEnhanced(from: capturedImages)
            await MainActor.run {
                items = result.items
                isAIEnhanced = result.isAIEnhanced
                processingState = .loaded(result.items)
                SubscriptionManager.shared.recordOCRUsage()
            }
        } catch {
            await MainActor.run {
                isAIEnhanced = false
                processingState = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Selection Actions

    func toggleSelection(for item: OCRRecordItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isSelected.toggle()
    }

    func selectAll() {
        for index in items.indices {
            items[index].isSelected = true
        }
    }

    func deselectAll() {
        for index in items.indices {
            items[index].isSelected = false
        }
    }

    func toggleSelectAll() {
        if isAllSelected {
            deselectAll()
        } else {
            selectAll()
        }
    }

    func deleteSelected() {
        items.removeAll { $0.isSelected }
    }

    // MARK: - Edit Actions

    func updateName(for itemID: UUID, newName: String) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        items[index].name = newName
    }

    func updateAmount(for itemID: UUID, newAmount: String) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        let cleaned = newAmount
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "，", with: "")
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "￥", with: "")
        if let value = Double(cleaned), value > 0 {
            items[index].amount = value
            items[index].amountText = newAmount
        }
    }

    // MARK: - Correction Sheet

    func startEditing(item: OCRRecordItem) {
        editingItem = item
        editName = item.name
        editAmountText = String(item.amount == Double(Int(item.amount)) ? "\(Int(item.amount))" : String(format: "%.2f", item.amount))
        editDate = item.date
        editEventName = item.eventName
    }

    func saveEditing() {
        guard let editingItem, let index = items.firstIndex(where: { $0.id == editingItem.id }) else { return }

        let cleanedAmount = editAmountText
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "，", with: "")
        let trimmedName = editName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else { return }

        items[index].name = trimmedName
        if let value = Double(cleanedAmount), value > 0 {
            items[index].amount = value
            items[index].amountText = editAmountText
        }
        items[index].date = editDate
        items[index].eventName = editEventName
        items[index].eventType = eventType(for: editEventName) ?? items[index].eventType

        self.editingItem = nil
    }

    var editAmountParsed: Double {
        let cleaned = editAmountText
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "，", with: "")
        return Double(cleaned) ?? 0
    }

    var chineseUppercaseAmount: String {
        ChineseAmountFormatter.chineseUppercase(editAmountParsed)
    }

    // MARK: - Import

    private func eventType(for eventName: String) -> EventType? {
        for type in EventType.allCases {
            if type.displayName == eventName {
                return type
            }
        }
        return nil
    }

    func performImport(context: ModelContext) -> Bool {
        let itemsToImport = selectedItems
        guard !itemsToImport.isEmpty else { return false }

        isImporting = true

        do {
            let contactDescriptor = FetchDescriptor<Contact>()
            let existingContacts = try context.fetch(contactDescriptor)
            var contactMap = Dictionary(
                existingContacts.map { ($0.name.trimmingCharacters(in: .whitespacesAndNewlines), $0) },
                uniquingKeysWith: { first, _ in first }
            )

            for item in itemsToImport {
                let normalizedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                let contact: Contact
                if let existing = contactMap[normalizedName] {
                    contact = existing
                } else {
                    contact = Contact(name: normalizedName)
                    context.insert(contact)
                    contactMap[normalizedName] = contact
                }

                let resolvedEventType = eventType(for: item.eventName) ?? item.eventType
                let event = ExportService.findOrCreateEventIfNeeded(
                    name: item.eventName,
                    type: resolvedEventType,
                    context: context
                )
                event?.date = item.date

                let record = Record(
                    contact: contact,
                    event: event,
                    direction: direction,
                    date: item.date
                )
                record.applyTypeData(.monetary(MonetaryData(amount: item.amount, paymentMethod: PaymentMethod.cash.rawValue)))
                record.updateStatus()
                context.insert(record)
            }

            try context.save()
            isImporting = false
            importSuccess = true
            return true
        } catch {
            isImporting = false
            importError = error.localizedDescription
            return false
        }
    }
}
