import PhotosUI
import SwiftData
import SwiftUI

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddEventViewModel()
    @State private var selectedCoverItem: PhotosPickerItem?

    var eventID: PersistentIdentifier?
    var defaultHostMode: EventHostMode

    init(eventID: PersistentIdentifier? = nil, defaultHostMode: EventHostMode = .guest) {
        self.eventID = eventID
        self.defaultHostMode = defaultHostMode
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
                    hostModeSection
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
        .trackScreen(eventID == nil ? "events.add" : "events.edit")
        .onAppear {
            if let eventID {
                if let event = modelContext.model(for: eventID) as? Event {
                    viewModel.configure(with: event)
                }
            } else if viewModel.name.isEmpty, viewModel.location.isEmpty, viewModel.note.isEmpty {
                viewModel.hostMode = defaultHostMode
            }
        }
        .onChange(of: selectedCoverItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self), !data.isEmpty,
                   let optimized = ImagePipeline.optimizedJPEGData(
                       from: data,
                       maxPixelSize: ImagePipeline.Preset.eventCoverMaxPixelSize,
                       compressionQuality: 0.84
                   )
                {
                    await MainActor.run {
                        viewModel.coverImageData = optimized
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
                    if let data = viewModel.coverImageData {
                        DecodedImageView(
                            data: data,
                            maxPixelSize: ImagePipeline.pixelSize(for: CGSize(width: 360, height: 140))
                        )
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
                            InteractionLogger.tap(
                                screen: eventID == nil ? "events.add" : "events.edit",
                                target: "events.editor.type.\(type.rawValue)"
                            )
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

    // MARK: - Host Mode Section

    private var hostModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "event.hostMode.title"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            Text(String(localized: "event.hostMode.subtitle"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            VStack(spacing: 10) {
                ForEach(EventHostMode.allCases, id: \.self) { mode in
                    hostModeRow(mode)
                }
            }
        }
    }

    private func hostModeRow(_ mode: EventHostMode) -> some View {
        Button {
            viewModel.hostMode = mode
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(
                            viewModel.hostMode == mode ? DesignSystem.Colors.primary : DesignSystem.Colors.border,
                            lineWidth: 1
                        )
                        .frame(width: 22, height: 22)

                    if viewModel.hostMode == mode {
                        Circle()
                            .fill(DesignSystem.Colors.primary)
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(hostModeHint(for: mode))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()
            }
            .padding(14)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(
                        viewModel.hostMode == mode ? DesignSystem.Colors.primary.opacity(0.4) : DesignSystem.Colors.border,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func hostModeHint(for mode: EventHostMode) -> String {
        switch mode {
        case .guest:
            String(localized: "event.hostMode.guestHint")
        case .host:
            String(localized: "event.hostMode.hostHint")
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
                InteractionLogger.tap(
                    screen: eventID == nil ? "events.add" : "events.edit",
                    target: "events.editor.cancel"
                )
                dismiss()
            }
            .buttonStyle(SecondaryButtonStyle())

            Button(String(localized: "common.save")) {
                saveEvent()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.isValid)
            .opacity(viewModel.isValid ? 1.0 : 0.6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.bgPage)
    }

    // MARK: - Helpers

    private func saveEvent() {
        if viewModel.save(context: modelContext) {
            InteractionLogger.submit(
                screen: eventID == nil ? "events.add" : "events.edit",
                target: "events.editor.save",
                action: .save,
                result: "success",
                metadata: ["event_name": viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines)]
            )
            dismiss()
        } else {
            InteractionLogger.submit(
                screen: eventID == nil ? "events.add" : "events.edit",
                target: "events.editor.save",
                action: .save,
                result: "failed",
                reason: "validation_or_persistence"
            )
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
            Text(String(localized: "common.preview.unavailable"))
        }
    }
}
