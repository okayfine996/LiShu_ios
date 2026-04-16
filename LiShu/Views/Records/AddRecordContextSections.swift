import SwiftData
import SwiftUI

struct AddRecordContextSelectionSection: View {
    let viewModel: AddRecordViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "record.add.context"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            Text(String(localized: "record.add.context.description"))
                .font(DesignSystem.Typography.small)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 0) {
                contextButton(.event, title: String(localized: "record.add.context.event"))
                contextButton(.daily, title: String(localized: "record.add.context.daily"))
            }
            .padding(4)
            .background(DesignSystem.Colors.bgInput)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
        }
    }

    private func contextButton(_ selection: RecordContextSelection, title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.setContextSelection(selection)
            }
        } label: {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(
                    viewModel.contextSelection == selection
                        ? DesignSystem.Colors.textPrimary
                        : DesignSystem.Colors.textTertiary
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(viewModel.contextSelection == selection ? DesignSystem.Colors.bgSurface : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.tag))
                .shadow(
                    color: viewModel.contextSelection == selection
                        ? DesignSystem.Colors.primary.opacity(DesignSystem.Effects.selectedShadowOpacity)
                        : .clear,
                    radius: DesignSystem.Effects.selectedShadowRadius,
                    y: DesignSystem.Effects.selectedShadowYOffset
                )
        }
        .buttonStyle(.plain)
    }
}

struct AddRecordEventSelectionSection: View {
    let viewModel: AddRecordViewModel
    let onCreateEvent: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.block) {
            if let selectedEvent = viewModel.selectedEvent {
                RecordEventSummaryCard(
                    title: String(localized: "record.add.relatedEvent"),
                    event: selectedEvent
                )
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                HStack {
                    Text(String(localized: "record.add.selectEvent"))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .tracking(1.5)
                        .textCase(.uppercase)
                    Spacer()
                }
                .padding(.horizontal, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.allEvents) { event in
                            eventButton(event)
                        }
                        createEventButton
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("record.add.eventSelector")

                if viewModel.allEvents.isEmpty {
                    Text(String(localized: "record.add.noEvent"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .padding(.horizontal, 4)
                }
            }
        }
    }

    private func eventButton(_ event: Event) -> some View {
        let isSelected = viewModel.selectedEvent?.persistentModelID == event.persistentModelID

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectEvent(event)
            }
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(DesignSystem.Effects.selectedFillOpacity) : .clear)
                    .frame(width: 60, height: 60)
                    .overlay {
                        EventCoverView(
                            coverImage: event.coverImage,
                            eventType: event.type,
                            size: 56,
                            placeholderBackground: DesignSystem.Colors.bgSurface
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                                .stroke(
                                    isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border.opacity(0.35),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                    }
                    .shadow(
                        color: isSelected ? DesignSystem.Colors.primary.opacity(DesignSystem.Effects.selectedShadowOpacity) : .clear,
                        radius: DesignSystem.Effects.selectedShadowRadius,
                        y: DesignSystem.Effects.selectedShadowYOffset
                    )

                Text(event.name)
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    .fontWeight(isSelected ? .medium : .regular)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 80)
            .opacity(viewModel.selectedEvent == nil || isSelected ? 1.0 : 0.7)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("record.add.event.\(event.name)")
    }

    private var createEventButton: some View {
        Button(action: onCreateEvent) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .fill(DesignSystem.Colors.bgSurface)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "plus")
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }

                Text(String(localized: "record.add.newEvent"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }
}

struct AddRecordDailyTagSection: View {
    let viewModel: AddRecordViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(localized: "record.add.dailyTag"))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: toggleCustomTag) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isCreatingCustomTag ? "xmark" : "plus")
                            .font(DesignSystem.Typography.small)
                        Text(
                            viewModel.isCreatingCustomTag
                                ? String(localized: "common.cancel")
                                : String(localized: "record.add.dailyTag.custom")
                        )
                        .font(DesignSystem.Typography.small)
                    }
                    .foregroundStyle(DesignSystem.Colors.primary)
                }
            }

            if viewModel.isCreatingCustomTag {
                HStack(spacing: 8) {
                    TextField(String(localized: "record.add.dailyTag.customPlaceholder"), text: customTagInputBinding)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .padding(10)
                        .background(DesignSystem.Colors.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )

                    Button(action: viewModel.addCustomTag) {
                        Text(String(localized: "common.confirm"))
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(DesignSystem.Colors.bgSurface)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isCustomTagValid ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                    }
                    .disabled(!isCustomTagValid)
                }
            }

            FlowLayout(spacing: 8) {
                ForEach(viewModel.allDailyTags, id: \.self) { tag in
                    dailyTagButton(tag)
                }
            }
        }
    }

    private var customTagInputBinding: Binding<String> {
        Binding(
            get: { viewModel.customTagInput },
            set: { viewModel.customTagInput = $0 }
        )
    }

    private var isCustomTagValid: Bool {
        !viewModel.customTagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func toggleCustomTag() {
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.isCreatingCustomTag.toggle()
            if !viewModel.isCreatingCustomTag {
                viewModel.customTagInput = ""
            }
        }
    }

    private func dailyTagButton(_ tag: String) -> some View {
        let isSelected = viewModel.selectedDailyTag == tag

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.selectedDailyTag = isSelected ? "" : tag
            }
        } label: {
            Text(tag)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? DesignSystem.Colors.primary.opacity(0.08) : DesignSystem.Colors.bgSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
