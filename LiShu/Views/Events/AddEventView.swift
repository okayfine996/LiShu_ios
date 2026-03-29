import SwiftUI
import SwiftData
import PhotosUI

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddEventViewModel()
    @State private var selectedCoverItem: PhotosPickerItem?

    var eventID: PersistentIdentifier?
    var prefill: FestivalEventPrefill?

    init(eventID: PersistentIdentifier? = nil, prefill: FestivalEventPrefill? = nil) {
        self.eventID = eventID
        self.prefill = prefill
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    nameSection
                    coverImageSection
                    typeSection
                    dateSection
                    locationSection
                    notesSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }

            // Bottom buttons
            bottomButtons
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(viewModel.editingEvent != nil ? String(localized: "event.edit.title") : String(localized: "event.add.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let eventID {
                if let event = modelContext.model(for: eventID) as? Event {
                    viewModel.configure(with: event)
                }
            } else if let prefill {
                viewModel.apply(prefill: prefill)
            }
        }
        .onChange(of: selectedCoverItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self), !data.isEmpty {
                    await MainActor.run {
                        viewModel.coverImageData = data
                    }
                }
            }
        }
    }

    // MARK: - Cover Image Section

    private var coverImageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "event.add.coverImage"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            PhotosPicker(
                selection: $selectedCoverItem,
                matching: .images
            ) {
                Group {
                    if let data = viewModel.coverImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "camera")
                                .font(.system(size: 36))
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                            Text(String(localized: "event.add.selectCover"))
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                .foregroundStyle(DesignSystem.Colors.border)
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                .background(DesignSystem.Colors.bgSurface)
            }
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "event.add.name"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            TextField(String(localized: "event.add.namePlaceholder"), text: $viewModel.name)
                .textFieldStyle(StandardTextFieldStyle())
                .accessibilityIdentifier("event.add.nameField")
        }
    }

    // MARK: - Type Section (horizontal pills)

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "event.add.type"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EventType.allCases, id: \.self) { type in
                        Button {
                            viewModel.eventType = type
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: type.iconName)
                                    .font(.system(size: 14))
                                Text(type.displayName)
                                    .font(DesignSystem.Typography.caption)
                            }
                            .foregroundStyle(viewModel.eventType == type ? .white : DesignSystem.Colors.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(viewModel.eventType == type ? DesignSystem.Colors.primary : DesignSystem.Colors.bgCard)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    viewModel.eventType == type ? DesignSystem.Colors.primary : DesignSystem.Colors.border,
                                    lineWidth: 1
                                )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Date Section (WeekStripDatePicker)

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "event.add.date"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            WeekStripDatePicker(selectedDate: $viewModel.date)
        }
    }

    // MARK: - Location Section

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "event.add.location"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            TextField(String(localized: "event.add.locationPlaceholder"), text: $viewModel.location)
                .textFieldStyle(StandardTextFieldStyle())
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "event.add.notes"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            TextEditor(text: $viewModel.note)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .frame(minHeight: 80)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(DesignSystem.Colors.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: 12) {
            Button(String(localized: "common.cancel")) {
                dismiss()
            }
            .buttonStyle(SecondaryButtonStyle())

            Button(String(localized: "common.save")) {
                saveEvent()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.isValid)
            .opacity(viewModel.isValid ? 1.0 : 0.6)
            .accessibilityIdentifier("event.add.saveButton")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.bgPage)
    }

    // MARK: - Helpers

    private func saveEvent() {
        if viewModel.save(context: modelContext) {
            dismiss()
        }
    }
}

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
            Text("Preview unavailable")
        }
    }
}

#Preview("Festival Prefill") {
    Group {
        if let container = try? ModelContainer(
            for: Contact.self, Record.self, Event.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ) {
            NavigationStack {
                AddEventView(
                    prefill: FestivalEventPrefill(
                        name: String(localized: "festival.midAutumnFestival"),
                        eventType: .festival,
                        date: Calendar.current.date(byAdding: .day, value: 12, to: .now) ?? .now
                    )
                )
            }
            .modelContainer(container)
        } else {
            Text("Preview unavailable")
        }
    }
}
