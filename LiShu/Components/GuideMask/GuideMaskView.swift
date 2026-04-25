import SwiftUI

// MARK: - SpotlightHoleShape

/// Full-screen rectangle with a rounded-rect "hole" cut through it using even-odd fill.
/// Conforms to `Animatable` so the spotlight position interpolates smoothly between steps.
struct SpotlightHoleShape: Shape {
    var spotlightRect: CGRect
    var cornerRadius: CGFloat

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            .init(
                .init(spotlightRect.origin.x, spotlightRect.origin.y),
                .init(spotlightRect.size.width, spotlightRect.size.height)
            )
        }
        set {
            spotlightRect = CGRect(
                x: newValue.first.first,
                y: newValue.first.second,
                width: newValue.second.first,
                height: newValue.second.second
            )
        }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRect(rect)
        p.addRoundedRect(
            in: spotlightRect,
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return p
    }
}

// MARK: - GuideCalloutView

/// The floating tooltip card shown near the spotlight.
struct GuideCalloutView: View {
    let step: GuideStep
    let stepIndex: Int
    let totalSteps: Int
    /// When `true` the step expects the user to tap a real button; "Next" is hidden.
    let isPassThrough: Bool
    let onSkip: () -> Void
    let onAdvance: () -> Void

    private var isLastStep: Bool {
        stepIndex == totalSteps - 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
            progressDots
            titleText
            bodyText
            actionButtons
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
        .padding(.horizontal, DesignSystem.Spacing.pageHorizontal)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i == stepIndex ? DesignSystem.Colors.primary : DesignSystem.Colors.border)
                    .frame(width: i == stepIndex ? 20 : 6, height: 6)
                    .animation(.spring(duration: 0.35), value: stepIndex)
            }
            Spacer()
        }
    }

    private var titleText: some View {
        Text(String(localized: String.LocalizationValue(step.titleKey)))
            .font(DesignSystem.Typography.title3)
            .foregroundStyle(DesignSystem.Colors.textPrimary)
    }

    private var bodyText: some View {
        Text(String(localized: String.LocalizationValue(step.bodyKey)))
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var actionButtons: some View {
        HStack(spacing: DesignSystem.Spacing.block) {
            // "Skip" always visible on non-last steps so user can bypass the current step.
            if !isLastStep {
                Button(String(localized: "guide.action.skip"), action: onSkip)
                    .buttonStyle(GhostButtonStyle())
            }
            // On passThrough steps the user must perform the real action (or skip).
            // Hide "Next" to make the intention clear; keep "Done" on the final step.
            if !isPassThrough || isLastStep {
                Button(
                    isLastStep
                        ? String(localized: "guide.action.done")
                        : String(localized: "guide.action.next"),
                    action: onAdvance
                )
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.top, DesignSystem.Spacing.stackTight)
    }
}

// MARK: - GuideMaskOverlay

/// The full-screen overlay composited above `MainTabView`.
/// Receives the resolved spotlight `CGRect` (in screen coordinates) from `GeometryReader`.
struct GuideMaskOverlay: View {
    let step: GuideStep
    let stepIndex: Int
    let totalSteps: Int
    /// `nil` when the step has no anchor or the anchor hasn't rendered yet.
    let spotlightFrame: CGRect?
    let screenSize: CGSize
    let onSkip: () -> Void
    let onAdvance: () -> Void

    private var paddedSpotlight: CGRect? {
        spotlightFrame.map { $0.insetBy(dx: -step.spotlightPadding, dy: -step.spotlightPadding) }
    }

    var body: some View {
        ZStack {
            // ── Dim layer ──────────────────────────────────────────────────────
            dimLayer

            // ── Callout card ───────────────────────────────────────────────────
            // For spotlight steps: adaptive positioning based on spotlight location.
            //   • Spotlight in top half  → callout appears just below the spotlight.
            //   • Spotlight in bottom half → callout appears in the upper area so it
            //     doesn't overlap the highlighted element.
            // For welcome/done (no anchor): centre vertically.
            if spotlightFrame != nil {
                VStack(spacing: 0) {
                    if let frame = paddedSpotlight, frame.midY < screenSize.height * 0.5 {
                        Spacer().frame(height: frame.maxY + 20)
                    } else {
                        Spacer().frame(height: screenSize.height * 0.08)
                    }
                    GuideCalloutView(
                        step: step,
                        stepIndex: stepIndex,
                        totalSteps: totalSteps,
                        isPassThrough: step.isPassThrough,
                        onSkip: onSkip,
                        onAdvance: onAdvance
                    )
                    Spacer(minLength: 0)
                }
            } else {
                VStack {
                    Spacer()
                    GuideCalloutView(
                        step: step,
                        stepIndex: stepIndex,
                        totalSteps: totalSteps,
                        isPassThrough: step.isPassThrough,
                        onSkip: onSkip,
                        onAdvance: onAdvance
                    )
                    Spacer()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step.anchorID == nil)
    }

    @ViewBuilder
    private var dimLayer: some View {
        if let spotlight = paddedSpotlight {
            if step.isPassThrough {
                // Pass-through: the overlay is visual-only — touches fall through to
                // the spotlighted button so the user can tap it directly.
                SpotlightHoleShape(spotlightRect: spotlight, cornerRadius: DesignSystem.Radius.smallCard)
                    .fill(style: FillStyle(eoFill: true))
                    .foregroundStyle(Color.black.opacity(0.72))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            } else {
                // Normal: tapping anywhere on the dim layer advances the guide.
                SpotlightHoleShape(spotlightRect: spotlight, cornerRadius: DesignSystem.Radius.smallCard)
                    .fill(style: FillStyle(eoFill: true))
                    .foregroundStyle(Color.black.opacity(0.72))
                    .ignoresSafeArea()
                    .onTapGesture { onAdvance() }
            }
        } else {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onAdvance() }
        }
    }
}

// MARK: - Environment Keys

/// Allows child views (e.g. SettingsView) to trigger a guide restart without a direct reference.
private struct GuideMaskRestartKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

/// The anchorID of the currently active guide step — lets scrollable views auto-scroll to the target.
private struct GuideCurrentAnchorKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    var restartGuideTour: () -> Void {
        get { self[GuideMaskRestartKey.self] }
        set { self[GuideMaskRestartKey.self] = newValue }
    }

    var guideCurrentAnchorID: String? {
        get { self[GuideCurrentAnchorKey.self] }
        set { self[GuideCurrentAnchorKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Attaches the guide overlay to a view hierarchy.
    /// Apply this to the `TabView` inside `MainTabView`.
    func guideMask(viewModel: GuideMaskViewModel) -> some View {
        // GuideAnchorKey now carries CGRect values in global coordinates, so no
        // anchor-resolution step is needed — we pass the rect straight through.
        overlayPreferenceValue(GuideAnchorKey.self) { frames in
            if viewModel.isActive, let step = viewModel.currentStep {
                GeometryReader { geo in
                    let spotlightFrame: CGRect? = step.anchorID.flatMap { frames[$0] }
                    GuideMaskOverlay(
                        step: step,
                        stepIndex: viewModel.currentStepIndex,
                        totalSteps: viewModel.steps.count,
                        spotlightFrame: spotlightFrame,
                        screenSize: geo.size,
                        onSkip: { viewModel.skip() },
                        onAdvance: { viewModel.advance() }
                    )
                    // Animate spotlight position changes between steps
                    .animation(.spring(duration: 0.45), value: viewModel.currentStepIndex)
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        // Animate overlay appearance / dismissal
        .animation(.easeInOut(duration: 0.3), value: viewModel.isActive)
    }
}

// MARK: - Previews

#Preview("With spotlight – passThrough") {
    let step = GuideStep(
        id: "guide.event.create",
        titleKey: "guide.event.create.title",
        bodyKey: "guide.event.create.body",
        anchorID: "event.list.addButton",
        spotlightPadding: 14,
        completionTrigger: .eventCreated,
        isPassThrough: true,
        requiredTab: .events
    )
    ZStack {
        DesignSystem.Colors.bgPage.ignoresSafeArea()
        VStack {
            Text("App content here")
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding()
            Spacer()
        }
        GuideMaskOverlay(
            step: step,
            stepIndex: 1,
            totalSteps: 5,
            spotlightFrame: CGRect(x: 340, y: 100, width: 44, height: 44),
            screenSize: CGSize(width: 393, height: 852),
            onSkip: {},
            onAdvance: {}
        )
    }
}

#Preview("Welcome card") {
    let step = GuideStep(
        id: "guide.welcome",
        titleKey: "guide.welcome.title",
        bodyKey: "guide.welcome.body"
    )
    ZStack {
        DesignSystem.Colors.bgPage.ignoresSafeArea()
        GuideMaskOverlay(
            step: step,
            stepIndex: 0,
            totalSteps: 5,
            spotlightFrame: nil,
            screenSize: CGSize(width: 393, height: 852),
            onSkip: {},
            onAdvance: {}
        )
    }
}
