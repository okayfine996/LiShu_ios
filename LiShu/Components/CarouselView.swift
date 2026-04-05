import SwiftUI

enum CarouselIndicatorPosition {
    case bottomCenter
    case bottomTrailing
    case topTrailing

    var alignment: Alignment {
        switch self {
        case .bottomCenter:
            .bottom
        case .bottomTrailing:
            .bottomTrailing
        case .topTrailing:
            .topTrailing
        }
    }

    var padding: EdgeInsets {
        switch self {
        case .bottomCenter:
            EdgeInsets(top: 0, leading: 0, bottom: DesignSystem.Spacing.cardPaddingSmall, trailing: 0)
        case .bottomTrailing:
            EdgeInsets(
                top: 0,
                leading: 0,
                bottom: DesignSystem.Spacing.cardPaddingSmall,
                trailing: DesignSystem.Spacing.cardPadding
            )
        case .topTrailing:
            EdgeInsets(
                top: DesignSystem.Spacing.cardPadding,
                leading: 0,
                bottom: 0,
                trailing: DesignSystem.Spacing.cardPadding
            )
        }
    }
}

struct CarouselView<Content: View>: View {
    private let pageCount: Int
    private let externalCurrentPage: Binding<Int>?
    private let indicatorPosition: CarouselIndicatorPosition
    private let showsIndicator: Bool
    private let contentInsets: EdgeInsets
    private let content: (Int) -> Content

    @State private var internalCurrentPage = 0

    init(
        pageCount: Int,
        currentPage: Binding<Int>? = nil,
        indicatorPosition: CarouselIndicatorPosition = .bottomCenter,
        showsIndicator: Bool = true,
        contentInsets: EdgeInsets = EdgeInsets(),
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.pageCount = pageCount
        externalCurrentPage = currentPage
        self.indicatorPosition = indicatorPosition
        self.showsIndicator = showsIndicator
        self.contentInsets = contentInsets
        self.content = content
    }

    private var currentPageBinding: Binding<Int> {
        externalCurrentPage ?? $internalCurrentPage
    }

    var body: some View {
        ZStack(alignment: indicatorPosition.alignment) {
            TabView(selection: currentPageBinding) {
                ForEach(0 ..< pageCount, id: \.self) { index in
                    content(index)
                        .padding(contentInsets)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            if showsIndicator, pageCount > 1 {
                pageIndicator(current: currentPageBinding.wrappedValue)
                    .padding(indicatorPosition.padding)
                    .allowsHitTesting(false)
            }
        }
    }

    private func pageIndicator(current: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0 ..< pageCount, id: \.self) { index in
                Circle()
                    .fill(index == current ? DesignSystem.Colors.primary : DesignSystem.Colors.border)
                    .frame(width: 6, height: 6)
            }
        }
    }
}
