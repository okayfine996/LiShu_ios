import SwiftData
import SwiftUI

struct CircleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CircleDetailViewModel()

    let circle: Int
    let year: Int

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                CircleDetailContentView(viewModel: viewModel)
            case let .error(message):
                ErrorStateView(message: message, retryAction: loadData)
            }
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(viewModel.circleName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadData)
    }

    private func loadData() {
        viewModel.load(circle: circle, year: year, context: modelContext)
    }
}

#Preview {
    CircleDetailPreview()
}
