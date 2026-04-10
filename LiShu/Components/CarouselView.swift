import Combine
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
    private enum AutoScrollBehavior {
        case disabled
        case enabled(interval: TimeInterval)
    }

    private let pageCount: Int
    private let externalCurrentPage: Binding<Int>?
    private let indicatorPosition: CarouselIndicatorPosition
    private let showsIndicator: Bool
    private let contentInsets: EdgeInsets
    private let autoScrollBehavior: AutoScrollBehavior
    private let content: (Int) -> Content

    @State private var internalCurrentPage = 0

    init(
        pageCount: Int,
        currentPage: Binding<Int>? = nil,
        indicatorPosition: CarouselIndicatorPosition = .bottomCenter,
        showsIndicator: Bool = true,
        contentInsets: EdgeInsets = EdgeInsets(),
        autoScrollInterval: TimeInterval? = nil,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.pageCount = pageCount
        externalCurrentPage = currentPage
        self.indicatorPosition = indicatorPosition
        self.showsIndicator = showsIndicator
        self.contentInsets = contentInsets
        if let autoScrollInterval, autoScrollInterval > 0 {
            autoScrollBehavior = .enabled(interval: autoScrollInterval)
        } else {
            autoScrollBehavior = .disabled
        }
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
            .onAppear {
                clampCurrentPage()
            }
            .onChange(of: pageCount) { _, _ in
                clampCurrentPage()
            }
            .onReceive(autoScrollTimer) { _ in
                guard pageCount > 1 else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentPageBinding.wrappedValue = (currentPageBinding.wrappedValue + 1) % pageCount
                }
            }

            if showsIndicator, pageCount > 1 {
                pageIndicator(current: currentPageBinding.wrappedValue)
                    .padding(indicatorPosition.padding)
                    .allowsHitTesting(false)
            }
        }
    }

    private var autoScrollTimer: Publishers.Autoconnect<Timer.TimerPublisher> {
        switch autoScrollBehavior {
        case .disabled:
            Timer.publish(every: 86400, on: .main, in: .common).autoconnect()
        case let .enabled(interval):
            Timer.publish(every: interval, on: .main, in: .common).autoconnect()
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

    private func clampCurrentPage() {
        let clampedPage = if pageCount > 0 {
            min(currentPageBinding.wrappedValue, pageCount - 1)
        } else {
            0
        }

        guard currentPageBinding.wrappedValue != clampedPage else { return }
        currentPageBinding.wrappedValue = clampedPage
    }
}
