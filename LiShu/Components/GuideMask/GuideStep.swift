import SwiftUI

// MARK: - CompletionTrigger

/// Defines how a guide step is marked as complete.
enum CompletionTrigger: Equatable {
    /// User taps "Next" or "Done" manually.
    case manual
    /// Auto-advances when a new Event is detected in the store.
    case eventCreated
    /// Auto-advances when a new Contact is detected in the store.
    case contactCreated
    /// Auto-advances when a new Record is detected in the store.
    case recordCreated
}

// MARK: - GuideStep

/// A single step in the feature guide tour.
struct GuideStep: Identifiable, Equatable {
    /// Unique identifier. For tab steps, matches the `anchorID` value.
    let id: String
    /// Localization key for the step title (e.g. `"guide.home.title"`).
    let titleKey: String
    /// Localization key for the step body (e.g. `"guide.home.body"`).
    let bodyKey: String
    /// The anchor ID to spotlight. When `nil`, the step shows a centred card with no spotlight.
    let anchorID: String?
    /// Extra padding (in points) added around the raw anchor frame. Positive = larger spotlight.
    let spotlightPadding: CGFloat
    /// Preferred edge for the callout card. Auto-positioning overrides this at runtime.
    let calloutPreferredEdge: Edge
    /// How this step advances. `.manual` = user taps Next; others = model count delta.
    let completionTrigger: CompletionTrigger
    /// When `true`, the spotlight overlay does not capture touch events so the
    /// highlighted button underneath remains fully interactive.
    let isPassThrough: Bool
    /// If set, `MainTabView` switches to this tab when the step becomes active.
    let requiredTab: AppTab?

    init(
        id: String,
        titleKey: String,
        bodyKey: String,
        anchorID: String? = nil,
        spotlightPadding: CGFloat = 8,
        calloutPreferredEdge: Edge = .bottom,
        completionTrigger: CompletionTrigger = .manual,
        isPassThrough: Bool = false,
        requiredTab: AppTab? = nil
    ) {
        self.id = id
        self.titleKey = titleKey
        self.bodyKey = bodyKey
        self.anchorID = anchorID
        self.spotlightPadding = spotlightPadding
        self.calloutPreferredEdge = calloutPreferredEdge
        self.completionTrigger = completionTrigger
        self.isPassThrough = isPassThrough
        self.requiredTab = requiredTab
    }
}

// MARK: - GuideAnchorKey

/// Carries global-coordinate `CGRect` values keyed by anchor ID.
///
/// Using `CGRect` (rather than `Anchor<CGRect>`) lets us capture the frame with
/// `GeometryReader { geo in geo.frame(in: .global) }` so the value is already
/// in screen coordinates.  This works reliably for toolbar buttons, which live
/// inside UIKit's UINavigationBar and cannot propagate `Anchor<CGRect>` through
/// the SwiftUI preference tree correctly.
struct GuideAnchorKey: PreferenceKey {
    typealias Value = [String: CGRect]
    static let defaultValue: Value = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - View Helper

extension View {
    /// Tags a view so the guide overlay can locate its on-screen frame.
    ///
    /// Internally attaches a transparent `GeometryReader` background that reads
    /// the view's frame in `.global` coordinates and publishes it via
    /// `GuideAnchorKey`.  This approach works inside toolbar items where the
    /// old `anchorPreference` mechanism fails.
    ///
    /// - Parameter id: Must match a `GuideStep.anchorID` value.
    func guideAnchor(id: String) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: GuideAnchorKey.self,
                    value: [id: geo.frame(in: .global)]
                )
            }
        )
    }
}
