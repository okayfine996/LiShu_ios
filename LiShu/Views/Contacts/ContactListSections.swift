import SwiftUI

struct ContactListStateContainer: View {
    @Bindable var viewModel: ContactListViewModel

    let onRetry: () -> Void
    let onAddContact: () -> Void
    let onSelectContact: (Contact) -> Void
    let onDeleteContact: (Contact) -> Void
    let onEditContact: (Contact) -> Void
    let onBatchImport: () -> Void

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case let .loaded(contacts) where contacts.isEmpty:
                EmptyStateView(
                    icon: "person.2.fill",
                    message: String(localized: "contact.list.empty"),
                    actionTitle: String(localized: "contact.add.title"),
                    action: onAddContact
                )
            case .loaded:
                ContactListLoadedContent(
                    viewModel: viewModel,
                    onSelectContact: onSelectContact,
                    onDeleteContact: onDeleteContact,
                    onEditContact: onEditContact
                )
            case let .error(message):
                ErrorStateView(message: message, retryAction: onRetry)
            }
        }
    }
}

private struct ContactListLoadedContent: View {
    @Bindable var viewModel: ContactListViewModel

    let onSelectContact: (Contact) -> Void
    let onDeleteContact: (Contact) -> Void
    let onEditContact: (Contact) -> Void

    var body: some View {
        List {
            ContactListRow(bottomInset: DesignSystem.Spacing.block) {
                Picker("", selection: $viewModel.selectedFilter) {
                    ForEach(ContactCircleFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            if viewModel.filteredContacts.isEmpty {
                ContactListRow(bottomInset: DesignSystem.Spacing.section) {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        message: String(localized: "contact.list.noResults")
                    )
                }
            } else {
                ForEach(viewModel.groupedContacts) { group in
                    ContactGroupSection(
                        group: group,
                        onSelectContact: onSelectContact,
                        onDeleteContact: onDeleteContact,
                        onEditContact: onEditContact
                    )
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.bgPage)
    }
}

private struct ContactGroupSection: View {
    let group: ContactGroup
    let onSelectContact: (Contact) -> Void
    let onDeleteContact: (Contact) -> Void
    let onEditContact: (Contact) -> Void

    var body: some View {
        Section {
            ForEach(group.contacts) { contact in
                ContactListItemRow(
                    contact: contact,
                    onSelect: { onSelectContact(contact) },
                    onDelete: { onDeleteContact(contact) },
                    onEdit: { onEditContact(contact) }
                )
            }
        } header: {
            Text(group.title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)
                .textCase(nil)
                .padding(.top, DesignSystem.Spacing.block)
        }
    }
}

private struct ContactListItemRow: View {
    let contact: Contact
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ContactRow(
                avatar: contact.avatar,
                name: contact.name,
                relation: contact.relation,
                netValue: contact.netValue
            )
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("contact.list.row.\(contact.name)")
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: onEdit) {
                Label(String(localized: "common.edit"), systemImage: "pencil")
            }
            .tint(DesignSystem.Colors.accentGold)

            Button(role: .destructive, action: onDelete) {
                Label(String(localized: "common.delete"), systemImage: "trash")
            }
        }
        .listRowInsets(EdgeInsets(
            top: 0,
            leading: DesignSystem.Spacing.pageHorizontal,
            bottom: DesignSystem.Spacing.block,
            trailing: DesignSystem.Spacing.pageHorizontal
        ))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

private struct ContactListRow<Content: View>: View {
    let bottomInset: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        content
            .listRowInsets(EdgeInsets(
                top: 0,
                leading: DesignSystem.Spacing.pageHorizontal,
                bottom: bottomInset,
                trailing: DesignSystem.Spacing.pageHorizontal
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

struct ContactListToolbarMenu: View {
    let onAddContact: () -> Void
    let onBatchImport: () -> Void
    let onExportXLSX: () -> Void
    let onImportXLSX: () -> Void
    let onDownloadTemplate: () -> Void

    var body: some View {
        Menu {
            Button(action: onAddContact) {
                Label(String(localized: "contact.add.title"), systemImage: "person.badge.plus")
            }

            Button(action: onBatchImport) {
                Label(String(localized: "contact.batch.import"), systemImage: "person.crop.rectangle.stack")
            }

            Divider()

            Button(action: onExportXLSX) {
                Label(String(localized: "contact.excel.export"), systemImage: "square.and.arrow.up")
            }

            Button(action: onImportXLSX) {
                Label(String(localized: "contact.excel.import"), systemImage: "square.and.arrow.down")
            }

            Button(action: onDownloadTemplate) {
                Label(String(localized: "contact.excel.template"), systemImage: "doc.text")
            }
        } label: {
            Image(systemName: "plus")
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(DesignSystem.Colors.primary)
        }
        .accessibilityIdentifier("contact.list.addButton")
    }
}
