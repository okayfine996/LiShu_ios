import SwiftUI

struct AISparkleIcon: View {
    @State private var isAnimating = false

    var body: some View {
        Image(systemName: "apple.intelligence")
            .font(.system(size: 48))
            .foregroundStyle(
                DesignSystem.Colors.primary.gradient
            )
            .symbolEffect(.variableColor.iterative.reversing, isActive: true)
            .scaleEffect(isAnimating ? 1.05 : 0.95)
            .animation(.easeInOut(duration: 1.5).repeatForever(), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}

#Preview {
    AISparkleIcon()
}
