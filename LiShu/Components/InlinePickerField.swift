import SwiftUI
import SwiftData

/// A reusable inline picker with search, selection list, and optional inline-create mode.
/// Used for both contact and event selection in AddRecordView.
struct InlinePickerField<Item: PersistentModel, CreateContent: View, CreateExtraContent: View>: View {
    let title: String
    let placeholder: String
    let placeholderIcon: String
    let searchPlaceholder: String
    let emptyText: String
    let newButtonTitle: String

    @Binding var selectedItem: Item?
    @Binding var isShowingPicker: Bool
    @Binding var searchText: String
    @Binding var isCreatingNew: Bool

    let items: [Item]
    let filteredItems: [Item]
    let itemName: (Item) -> String
    let itemIcon: (Item) -> AnyView
    let onToggleCreate: () -> Void
    @ViewBuilder let createContent: () -> CreateContent
    @ViewBuilder let createExtraContent: () -> CreateExtraContent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            contentArea
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)

            Spacer()

            Button {
                withAnimation {
                    onToggleCreate()
                }
            } label: {
                Text(isCreatingNew ? String(localized: "common.cancel") : newButtonTitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.primary)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if isCreatingNew {
            VStack(spacing: 8) {
                createContent()
                    .frame(minHeight: 36)
                    .padding(12)
                    .background(DesignSystem.Colors.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )

                createExtraContent()
            }
        } else if isShowingPicker {
            pickerContent
        } else {
            collapsedButton
        }
    }

    // MARK: - Collapsed

    private var collapsedButton: some View {
        Button {
            withAnimation {
                isShowingPicker = true
            }
        } label: {
            HStack(spacing: 12) {
                if let item = selectedItem {
                    itemIcon(item)
                    Text(itemName(item))
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                } else {
                    Image(systemName: placeholderIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .frame(width: 36, height: 36)

                    Text(placeholder)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(12)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Picker

    private var pickerContent: some View {
        VStack(spacing: 8) {
            searchField
            itemList
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            TextField(searchPlaceholder, text: $searchText)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Button {
                withAnimation {
                    isShowingPicker = false
                    searchText = ""
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(12)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var itemList: some View {
        if filteredItems.isEmpty {
            Text(emptyText)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .padding(.vertical, 12)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(filteredItems) { item in
                        Button {
                            selectedItem = item
                            withAnimation {
                                isShowingPicker = false
                                searchText = ""
                            }
                        } label: {
                            HStack(spacing: 12) {
                                itemIcon(item)

                                Text(itemName(item))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                                Spacer()

                                if item.persistentModelID == selectedItem?.persistentModelID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(DesignSystem.Colors.primary)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .foregroundStyle(DesignSystem.Colors.separator)
                    }
                }
            }
            .frame(maxHeight: 200)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Convenience init without extra content

extension InlinePickerField where CreateExtraContent == EmptyView {
    init(
        title: String,
        placeholder: String,
        placeholderIcon: String,
        searchPlaceholder: String,
        emptyText: String,
        newButtonTitle: String,
        selectedItem: Binding<Item?>,
        isShowingPicker: Binding<Bool>,
        searchText: Binding<String>,
        isCreatingNew: Binding<Bool>,
        items: [Item],
        filteredItems: [Item],
        itemName: @escaping (Item) -> String,
        itemIcon: @escaping (Item) -> AnyView,
        onToggleCreate: @escaping () -> Void,
        @ViewBuilder createContent: @escaping () -> CreateContent
    ) {
        self.title = title
        self.placeholder = placeholder
        self.placeholderIcon = placeholderIcon
        self.searchPlaceholder = searchPlaceholder
        self.emptyText = emptyText
        self.newButtonTitle = newButtonTitle
        self._selectedItem = selectedItem
        self._isShowingPicker = isShowingPicker
        self._searchText = searchText
        self._isCreatingNew = isCreatingNew
        self.items = items
        self.filteredItems = filteredItems
        self.itemName = itemName
        self.itemIcon = itemIcon
        self.onToggleCreate = onToggleCreate
        self.createContent = createContent
        self.createExtraContent = { EmptyView() }
    }
}
