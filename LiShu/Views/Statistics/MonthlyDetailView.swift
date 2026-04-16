import SwiftData
import SwiftUI

struct MonthlyDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MonthlyDetailViewModel()

    let period: StatsPeriod

    var body: some View {
        MonthlyDetailContentView(viewModel: viewModel)
            .background(DesignSystem.Colors.bgPage)
            .navigationTitle(viewModel.periodTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadData)
    }

    private func loadData() {
        viewModel.load(period: period, context: modelContext)
    }
}
