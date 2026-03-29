import SwiftUI

struct CapsuleSegmentedControl<T: Hashable>: View {
    let options: [T]
    @Binding var selected: T
    let titleForOption: (T) -> String

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = option
                    }
                } label: {
                    Text(titleForOption(option))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(
                            selected == option
                                ? DesignSystem.Colors.textOnPrimary
                                : DesignSystem.Colors.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selected == option {
                                Capsule()
                                    .fill(DesignSystem.Colors.primary)
                                    .matchedGeometryEffect(id: "capsule", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(DesignSystem.Colors.bgCard)
        .clipShape(Capsule())
    }
}
