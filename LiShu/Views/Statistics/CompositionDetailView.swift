import SwiftData
import SwiftUI

struct CompositionDetailView: View {
    enum Mode: Hashable {
        case recordTypes(year: Int)
        case eventTypes(year: Int)
    }

    @Environment(\.modelContext) private var modelContext
    @State private var recordViewModel = RecordTypeCompositionViewModel()
    @State private var eventTypeViewModel = EventTypeCompositionViewModel()

    let mode: Mode

    private var navigationTitle: String {
        switch mode {
        case .recordTypes:
            String(localized: "recordTypeComposition.title")
        case .eventTypes:
            String(localized: "eventTypeComposition.title")
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                switch mode {
                case .recordTypes:
                    CompositionRecordTypesContent(viewModel: recordViewModel)
                case .eventTypes:
                    CompositionEventTypesContent(viewModel: eventTypeViewModel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(DesignSystem.Colors.bgPage)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadData)
    }

    private func loadData() {
        switch mode {
        case let .recordTypes(year):
            recordViewModel.load(year: year, context: modelContext)
        case let .eventTypes(year):
            eventTypeViewModel.load(year: year, context: modelContext)
        }
    }
}

#Preview("人情构成") {
    CompositionRecordTypesPreview()
}

#Preview("事件分布") {
    CompositionEventTypesPreview()
}
