import SwiftUI

struct ContactDetailContentView: View {
    let contact: Contact
    let viewModel: ContactDetailViewModel
    @Binding var currentCardPage: Int
    let onAddRecord: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ContactDetailProfileSection(contact: contact)
            ContactDetailSummaryCardsSection(
                contact: contact,
                viewModel: viewModel,
                currentCardPage: $currentCardPage
            )
            ContactDetailPersonalInfoSection(contact: contact, viewModel: viewModel)
            ContactDetailTimelineSection(
                records: viewModel.sortedRecords,
                viewModel: viewModel,
                onAddRecord: onAddRecord
            )
        }
    }
}
