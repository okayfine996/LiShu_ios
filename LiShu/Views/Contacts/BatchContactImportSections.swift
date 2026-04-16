import SwiftUI

struct BatchContactImportStateView: View {
    let accessState: BatchContactImportViewModel.AccessState
    @Bindable var viewModel: BatchContactImportViewModel
    let onImport: () -> Void

    var body: some View {
        Group {
            switch accessState {
            case .idle, .loading:
                ProgressView()
            case .denied:
                EmptyStateView(
                    icon: "person.crop.circle.badge.exclamationmark",
                    message: String(localized: "contact.import.noAccess")
                )
            case .empty:
                EmptyStateView(
                    icon: "person.2.slash",
                    message: String(localized: "contact.import.empty")
                )
            case .granted:
                BatchContactImportContentView(viewModel: viewModel, onImport: onImport)
            }
        }
    }
}

private struct BatchContactImportContentView: View {
    @Bindable var viewModel: BatchContactImportViewModel
    let onImport: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            BatchContactImportSearchBar(searchText: $viewModel.searchText)
            BatchContactImportList(
                items: viewModel.filteredItems,
                selectedIDs: viewModel.selectedIDs,
                onToggleSelection: viewModel.toggleSelection(_:)
            )
            BatchContactImportBottomBar(
                selectedCount: viewModel.selectedCount,
                isLoadingImport: viewModel.isLoadingImport,
                onImport: onImport
            )
        }
    }
}

private struct BatchContactImportSearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            TextField(String(localized: "contact.import.search"), text: $searchText)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct BatchContactImportList: View {
    let items: [PhoneContactItem]
    let selectedIDs: Set<String>
    let onToggleSelection: (String) -> Void

    var body: some View {
        List {
            ForEach(items) { item in
                BatchContactImportRow(
                    item: item,
                    isSelected: selectedIDs.contains(item.id),
                    onToggleSelection: { onToggleSelection(item.id) }
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

private struct BatchContactImportRow: View {
    let item: PhoneContactItem
    let isSelected: Bool
    let onToggleSelection: () -> Void

    private var isSelectable: Bool {
        !item.isExisting
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggleIfPossible) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selectionColor)
            }
            .disabled(!isSelectable)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.displayName)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    if item.isExisting {
                        Text(String(localized: "contact.import.exists"))
                            .font(DesignSystem.Typography.small)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.bgTag)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.tag))
                    }
                }

                if !item.phone.isEmpty {
                    Text(item.phone)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .listRowInsets(EdgeInsets())
        .listRowBackground(DesignSystem.Colors.bgSurface)
    }

    private var selectionColor: Color {
        if isSelectable {
            isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary
        } else {
            DesignSystem.Colors.textTertiary.opacity(0.5)
        }
    }

    private func toggleIfPossible() {
        if isSelectable {
            onToggleSelection()
        }
    }
}

private struct BatchContactImportBottomBar: View {
    let selectedCount: Int
    let isLoadingImport: Bool
    let onImport: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DesignSystem.Colors.separator)
                .frame(height: 1)

            Button(action: onImport) {
                if isLoadingImport {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(String(format: String(localized: "contact.import.button"), Int64(selectedCount)))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selectedCount == 0 || isLoadingImport)
            .padding(16)
        }
        .background(DesignSystem.Colors.bgPage)
    }
}
