import Foundation
import Logging

private let guideMaskLogger = PulseDiagnostics.makeLogger(label: AppLogLabel.uiGuide)

@Observable
@MainActor
final class GuideMaskViewModel {
    // MARK: - State

    private(set) var isActive: Bool = false
    private(set) var currentStepIndex: Int = 0
    private(set) var steps: [GuideStep] = []

    // MARK: - Base counts (for delta detection)

    private var baseEventCount = 0
    private var baseContactCount = 0
    private var baseRecordCount = 0

    // MARK: - Computed

    var currentStep: GuideStep? {
        guard isActive, steps.indices.contains(currentStepIndex) else { return nil }
        return steps[currentStepIndex]
    }

    private var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }

    /// The `AppTab` that should be selected for the current step.
    /// Reads directly from `GuideStep.requiredTab` — no switch mapping needed.
    var requiredTab: AppTab? {
        currentStep?.requiredTab
    }

    // MARK: - Public API

    func start(flow: [GuideStep], eventCount: Int = 0, contactCount: Int = 0, recordCount: Int = 0) {
        guard !flow.isEmpty else { return }
        baseEventCount = eventCount
        baseContactCount = contactCount
        baseRecordCount = recordCount
        steps = flow
        currentStepIndex = 0
        isActive = true
        guideMaskLogger.notice("Guide started", metadata: [
            "action": .string("start"),
            "step_count": .stringConvertible(flow.count),
        ])
    }

    func advance() {
        guard isActive else { return }
        if isLastStep {
            finish()
        } else {
            currentStepIndex += 1
            guideMaskLogger.info("Guide advanced", metadata: [
                "action": .string("advance"),
                "step_index": .stringConvertible(currentStepIndex),
                "step_id": .string(currentStep?.id ?? "unknown"),
            ])
        }
    }

    func skip() {
        guideMaskLogger.notice("Guide step skipped", metadata: [
            "action": .string("skip"),
            "step_index": .stringConvertible(currentStepIndex),
        ])
        advance()
    }

    func finish() {
        guideMaskLogger.notice("Guide finished", metadata: ["action": .string("finish")])
        dismiss()
    }

    /// Called by `MainTabView` whenever SwiftData model counts change.
    /// Compares against base counts recorded at `start(...)` to detect new creations.
    func notifyDataChanged(eventCount: Int, contactCount: Int, recordCount: Int) {
        guard isActive, let step = currentStep else { return }
        switch step.completionTrigger {
        case .eventCreated where eventCount > baseEventCount:
            guideMaskLogger.info("Guide auto-advanced: event created", metadata: ["action": .string("autoAdvance")])
            advance()
        case .contactCreated where contactCount > baseContactCount:
            guideMaskLogger.info("Guide auto-advanced: contact created", metadata: ["action": .string("autoAdvance")])
            advance()
        case .recordCreated where recordCount > baseRecordCount:
            guideMaskLogger.info("Guide auto-advanced: record created", metadata: ["action": .string("autoAdvance")])
            advance()
        default:
            break
        }
    }

    // MARK: - Private

    private func dismiss() {
        isActive = false
        currentStepIndex = 0
        steps = []
    }
}
