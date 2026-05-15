import SwiftUI

enum WidgetGallerySection {
    case home
    case lock
}

// MARK: - Widget Gallery

struct WidgetGalleryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var section: WidgetGallerySection = .home

    private let snapshot = WidgetGalleryPreviewData.sampleSnapshot

    var body: some View {
        ZStack(alignment: .top) {
            WidgetGalleryAmbientBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    WidgetGalleryHeroView(snapshot: snapshot)
                    WidgetGallerySegmentedControl(section: $section)
                    if section == .home {
                        WidgetGalleryHomeWidgets(snapshot: snapshot)
                    } else {
                        WidgetGalleryLockWidgets(snapshot: snapshot)
                    }
                    HowToAddAccordion(section: section)
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                    WidgetGalleryFooter()
                }
                .padding(.bottom, 32)
            }
        }
        .background(colorScheme == .dark ? Color(red: 0.110, green: 0.106, blue: 0.098) : Color(red: 0.961, green: 0.937, blue: 0.902))
        .navigationTitle(String(localized: "settings.widgetGallery"))
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("settings.widgetGallery")
    }
}

#Preview {
    NavigationStack {
        WidgetGalleryView()
    }
    .environment(SubscriptionManager.shared)
    .environment(AppSettings.shared)
}
