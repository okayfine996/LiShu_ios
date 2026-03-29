
import SwiftUI

struct DesignSystemView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    ColorPaletteSection()
                    TypographySection()
                    ComponentsSection()
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
                .padding(.top, 24)
            }
            .background(DesignSystem.Colors.bgPage.ignoresSafeArea())
            .navigationTitle("Design System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.backward")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
            }
        }
    }
}

// MARK: - Color Palette

private struct ColorPaletteSection: View {
    private let swatches: [(name: String, subtitle: String, color: Color)] = [
        ("bgPage", "Neutral-50", DesignSystem.Colors.bgPage),
        ("bgSubtle", "Surface L1", DesignSystem.Colors.bgCard),
        ("Surface", "Surface L2", DesignSystem.Colors.bgInput),
        ("Border", "Separator", DesignSystem.Colors.border),
        ("Accent", "Primary-500", DesignSystem.Colors.primary),
        ("Text Pri", "Neutral-900", DesignSystem.Colors.textPrimary),
        ("Text Sec", "Neutral-600", DesignSystem.Colors.textSecondary),
        ("Text Ter", "Neutral-400", DesignSystem.Colors.textTertiary),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Color Palette", icon: "paintpalette")

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
                spacing: 20
            ) {
                ForEach(swatches, id: \.name) { swatch in
                    ColorSwatchItem(
                        name: swatch.name,
                        subtitle: swatch.subtitle,
                        color: swatch.color,
                        isAccent: swatch.name == "Accent"
                    )
                }
            }

            colorInfoTable
        }
    }

    private var colorInfoTable: some View {
        VStack(spacing: 0) {
            ColorInfoRow(
                label: "Primary Text",
                lightValue: "#2C2C2C",
                darkValue: "#E6E1DC"
            )
            Divider().background(DesignSystem.Colors.border.opacity(0.4))
            ColorInfoRow(
                label: "Accent Color",
                lightValue: "#B76E5A",
                darkValue: "#B76E5A",
                valueColor: DesignSystem.Colors.primary
            )
            Divider().background(DesignSystem.Colors.border.opacity(0.4))
            ColorInfoRow(
                label: "Border Color",
                lightValue: "#D9CFC4",
                darkValue: "#3D3935"
            )
        }
        .background(DesignSystem.Colors.bgCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct ColorSwatchItem: View {
    let name: String
    let subtitle: String
    let color: Color
    var isAccent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(name.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isAccent ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                Text(subtitle)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
    }
}

private struct ColorInfoRow: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String
    let lightValue: String
    let darkValue: String
    var valueColor: Color = DesignSystem.Colors.textPrimary

    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(colorScheme == .dark ? darkValue : lightValue)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(valueColor)
        }
        .padding()
    }
}

// MARK: - Typography

private struct TypographySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Typography", icon: "textformat")

            VStack(spacing: 24) {
                TypographyRow(
                    label: "Title 1", meta: "28pt / Bold",
                    text: "Li Shang Wang Lai",
                    font: DesignSystem.Typography.title1
                )
                TypographyRow(
                    label: "Title 2", meta: "22pt / Bold",
                    text: "Design Specification",
                    font: DesignSystem.Typography.title2
                )
                TypographyRow(
                    label: "Title 3", meta: "20pt / Semibold",
                    text: "Component Library",
                    font: DesignSystem.Typography.title3
                )
                TypographyRow(
                    label: "Body", meta: "16pt / Regular",
                    text: "A clean, technical but elegant layout designed for clarity and usability across mobile devices.",
                    font: DesignSystem.Typography.body
                )

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CAPTION")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        Text("Secondary text (14pt)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("SMALL")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        Text("Meta info (11pt)")
                            .font(DesignSystem.Typography.small)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }
            }
            .padding(24)
            .background(DesignSystem.Colors.bgCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

private struct TypographyRow: View {
    let label: String
    let meta: String
    let text: String
    let font: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                Spacer()
                Text(meta)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }

            Text(text)
                .font(font)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Divider().background(DesignSystem.Colors.border.opacity(0.4))
        }
    }
}

// MARK: - Components

private struct ComponentsSection: View {
    @State private var textInput = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Components", icon: "square.grid.2x2")

            VStack(alignment: .leading, spacing: 24) {
                buttonsSubsection
                cardsSubsection
                formElementsSubsection
            }
        }
    }

    private var buttonsSubsection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BUTTONS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textSecondary)

            HStack(spacing: 12) {
                Button("Primary") { }
                    .buttonStyle(PrimaryButtonStyle())
                Button("Secondary") { }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Ghost") { }
                    .buttonStyle(GhostButtonStyle())
            }
        }
    }

    private var cardsSubsection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CARDS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textSecondary)

            standardCardExample
            listItemCardExample
        }
    }

    private var standardCardExample: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: "pencil.and.outline")
                        .foregroundColor(DesignSystem.Colors.primary)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Standard Card")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Text("Corner Radius: 20pt")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "shippingbox")
                    .font(.system(size: 28))
                    .foregroundColor(DesignSystem.Colors.primary.opacity(0.15))
            }
            .padding(.bottom, 16)

            Divider().background(DesignSystem.Colors.border.opacity(0.5))
                .padding(.bottom, 16)

            HStack {
                Text("Padding: 16pt")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                Spacer()
                Text("Action")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.bgCard)
        .cornerRadius(DesignSystem.Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
        )
    }

    private var listItemCardExample: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(DesignSystem.Colors.bgInput)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("List Item Card")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text("Radius: 14pt")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(DesignSystem.Colors.textTertiary)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(12)
        .background(DesignSystem.Colors.bgInput)
        .cornerRadius(DesignSystem.Radius.smallCard)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
        )
    }

    private var formElementsSubsection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FORM ELEMENTS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textSecondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Label Text")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.leading, 4)

                ZStack(alignment: .trailing) {
                    TextField("Input placeholder", text: $textInput)
                        .textFieldStyle(StandardTextFieldStyle())

                    Image(systemName: "pencil")
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .padding(.trailing, 16)
                }
            }

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 20, height: 20)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("Selected State")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
            }
            .padding(12)
            .background(DesignSystem.Colors.primary.opacity(0.1))
            .cornerRadius(DesignSystem.Radius.smallCard)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.smallCard)
                    .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    
        DesignSystemView()
            .preferredColorScheme(.light)
    
}


#Preview {
    
        DesignSystemView()
            .preferredColorScheme(.dark)
    
}
