import SwiftUI

struct RelationTagPicker: View {
    @Binding var selectedCategory: RelationshipCategory?
    @Binding var selectedTag: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            categoryChips
            tagDropdown
        }
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        HStack(spacing: 8) {
            ForEach(RelationshipCategory.allCases) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedCategory = category
                        selectedTag = ""
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 13))
                        Text(category.rawValue)
                            .font(DesignSystem.Typography.caption)
                    }
                    .foregroundStyle(
                        selectedCategory == category
                            ? DesignSystem.Colors.textOnPrimary
                            : DesignSystem.Colors.textPrimary
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        selectedCategory == category
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.bgTag
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tag Dropdown

    private var tagDropdown: some View {
        Menu {
            if let category = selectedCategory {
                ForEach(category.tags, id: \.self) { tag in
                    Button {
                        selectedTag = tag
                    } label: {
                        if selectedTag == tag {
                            Label(tag, systemImage: "checkmark")
                        } else {
                            Text(tag)
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(
                    selectedTag.isEmpty
                        ? String(localized: "contact.add.selectRelation")
                        : selectedTag
                )
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(
                    selectedTag.isEmpty
                        ? DesignSystem.Colors.textTertiary
                        : DesignSystem.Colors.textPrimary
                )

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(DesignSystem.Colors.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.input)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
        .disabled(selectedCategory == nil)
        .opacity(selectedCategory == nil ? 0.5 : 1)
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ArrangementResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        let totalHeight = y + rowHeight
        return ArrangementResult(
            positions: positions,
            sizes: sizes,
            size: CGSize(width: maxWidth, height: totalHeight)
        )
    }

    private struct ArrangementResult {
        var positions: [CGPoint]
        var sizes: [CGSize]
        var size: CGSize
    }
}
