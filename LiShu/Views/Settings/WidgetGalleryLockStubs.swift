import SwiftUI

struct GalleryCircularStub: View {
    let badgeCount: Int
    var body: some View {
        Circle()
            .fill(DesignSystem.Colors.textOnPrimary.opacity(0.18))
            .overlay(Circle().strokeBorder(DesignSystem.Colors.textOnPrimary.opacity(0.35), lineWidth: 0.5))
            .overlay(Image(systemName: "bell.fill").font(DesignSystem.Typography.widgetBodyBold)
                .foregroundStyle(DesignSystem.Colors.textOnPrimary))
            .overlay(alignment: .topTrailing) {
                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(DesignSystem.Typography.widgetMetaBold).foregroundStyle(DesignSystem.Colors.overlayDark)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Circle().fill(DesignSystem.Colors.textOnPrimary))
                        .padding(8)
                }
            }
            .frame(width: 76, height: 76)
    }
}

struct GalleryCircularCountdownStub: View {
    let daysUntil: Int
    private var progress: CGFloat {
        CGFloat(max(0, 30 - daysUntil)) / 30.0
    }

    var body: some View {
        ZStack {
            Circle().fill(DesignSystem.Colors.textOnPrimary.opacity(0.18))
                .overlay(Circle().strokeBorder(DesignSystem.Colors.textOnPrimary.opacity(0.35), lineWidth: 0.5))
            Circle().stroke(DesignSystem.Colors.textOnPrimary.opacity(0.18), lineWidth: 3).frame(width: 62, height: 62)
            Circle().trim(from: 0, to: progress)
                .stroke(DesignSystem.Colors.textOnPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 62, height: 62)
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("D–").font(DesignSystem.Typography.widgetMetaBold).foregroundStyle(DesignSystem.Colors.textOnPrimary).opacity(0.85)
                Text("\(daysUntil)").font(DesignSystem.Typography.widgetTitleLarge).foregroundStyle(DesignSystem.Colors.textOnPrimary)
                    .kerning(-1)
            }
        }
        .frame(width: 76, height: 76)
    }
}

struct GalleryRectangularStub: View {
    let snapshot: WidgetSnapshot
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(DesignSystem.Colors.textOnPrimary.opacity(0.18))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(DesignSystem.Colors.textOnPrimary.opacity(0.35), lineWidth: 0.5)
            )
            .overlay(
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        GalleryMark(size: 14)
                        Text(String(localized: "widget.displayName")).font(DesignSystem.Typography.widgetBodyBold)
                            .foregroundStyle(DesignSystem.Colors.textOnPrimary)
                        Spacer()
                        if let item = snapshot.reminders.first {
                            Text(item.dateLabel)
                                .font(DesignSystem.Typography.widgetMetaBold).foregroundStyle(DesignSystem.Colors.textOnPrimary)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(DesignSystem.Colors.textOnPrimary.opacity(0.20)))
                        }
                    }
                    if let item = snapshot.reminders.first {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title).font(DesignSystem.Typography.widgetBodyBold).foregroundStyle(DesignSystem.Colors.textOnPrimary)
                                .lineLimit(1)
                            Text(item.eventDateLabel.map { "\($0) · \(item.subtitle)" } ?? item.subtitle)
                                .font(DesignSystem.Typography.widgetMeta).foregroundStyle(DesignSystem.Colors.textOnPrimary.opacity(0.78))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
            )
            .frame(width: 172, height: 76)
    }
}

struct GalleryInlineStub: View {
    let snapshot: WidgetSnapshot
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "bell.fill").font(DesignSystem.Typography.widgetMetaBold).foregroundStyle(DesignSystem.Colors.textOnPrimary)
            if let item = snapshot.reminders.first {
                Text("\(String(localized: "widget.displayName")) · \(item.title) · \(item.dateLabel)")
                    .font(DesignSystem.Typography.widgetMeta).foregroundStyle(DesignSystem.Colors.textOnPrimary).lineLimit(1)
            }
        }
        .frame(width: 257, height: 18)
    }
}

#Preview("Widget Gallery Lock Stubs") {
    VStack(spacing: 18) {
        GalleryCircularStub(badgeCount: WidgetSnapshot.galleryPreview.reminderCount)
        GalleryCircularCountdownStub(daysUntil: WidgetSnapshot.galleryPreview.nextHostingEvent?.daysUntil ?? 7)
        GalleryRectangularStub(snapshot: .galleryPreview)
        GalleryInlineStub(snapshot: .galleryPreview)
    }
    .padding()
    .background(DesignSystem.Colors.bgCard)
}
