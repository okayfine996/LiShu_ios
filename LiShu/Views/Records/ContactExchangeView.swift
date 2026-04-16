import SwiftData
import SwiftUI

struct ContactExchangeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ContactExchangeViewModel()

    let contactID: PersistentIdentifier

    var body: some View {
        ZStack {
            DesignSystem.Colors.bgPage
                .ignoresSafeArea()

            if let contact = viewModel.contact {
                ContactExchangeContentView(
                    contact: contact,
                    records: viewModel.records,
                    totalGivenText: viewModel.formatAmount(viewModel.totalGiven),
                    totalReceivedText: viewModel.formatAmount(viewModel.totalReceived),
                    netLabel: viewModel.netLabel,
                    netAmountText: viewModel.formatAmount(abs(viewModel.netValue)),
                    givenRatio: viewModel.givenRatio,
                    lastContactText: viewModel.lastContactText,
                    formatDate: viewModel.formatDate,
                    amountText: amountText(for:)
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(
            viewModel.contact.map {
                String(format: String(localized: "exchange.title"), $0.name)
            } ?? ""
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadData)
    }

    private func loadData() {
        viewModel.load(contactID: contactID, context: modelContext)
    }

    private func amountText(for record: Record) -> String {
        let prefix = record.direction == .received ? "+ " : "- "
        return prefix + viewModel.formatAmount(record.resolvedDisplayAmount)
    }
}
