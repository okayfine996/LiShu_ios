import SwiftUI

struct GalleryCircularStub: View {
    let count: Int
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.18))
            .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5))
            .overlay(Image(systemName: "bell.fill").font(.system(size: 28)).foregroundStyle(.white))
            .overlay(alignment: .topTrailing) {
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .heavy)).foregroundStyle(.black)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Circle().fill(.white))
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
            Circle().fill(Color.white.opacity(0.18))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5))
            Circle().stroke(Color.white.opacity(0.18), lineWidth: 3).frame(width: 62, height: 62)
            Circle().trim(from: 0, to: progress)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 62, height: 62)
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("D–").font(.system(size: 10, weight: .bold)).foregroundStyle(.white).opacity(0.85)
                Text("\(daysUntil)").font(.system(size: 26, weight: .heavy)).foregroundStyle(.white).kerning(-1)
            }
        }
        .frame(width: 76, height: 76)
    }
}

struct GalleryRectangularStub: View {
    let snapshot: WidgetSnapshot
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.18))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
            )
            .overlay(
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        GalleryMark(size: 14)
                        Text(String(localized: "widget.displayName")).font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                        Spacer()
                        if let item = snapshot.reminders.first {
                            Text(item.dateLabel)
                                .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color.white.opacity(0.20)))
                        }
                    }
                    if let item = snapshot.reminders.first {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title).font(.system(size: 15, weight: .heavy)).foregroundStyle(.white).lineLimit(1)
                            Text(item.eventDateLabel.map { "\($0) · \(item.subtitle)" } ?? item.subtitle)
                                .font(.system(size: 10.5, weight: .semibold)).foregroundStyle(.white.opacity(0.78)).lineLimit(1)
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
            Image(systemName: "bell.fill").font(.system(size: 13)).foregroundStyle(.white)
            if let item = snapshot.reminders.first {
                Text("\(String(localized: "widget.displayName")) · \(item.title) · \(item.dateLabel)")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
            }
        }
        .frame(width: 257, height: 18)
    }
}

#Preview("Widget Gallery Lock Stubs") {
    VStack(spacing: 18) {
        GalleryCircularStub(count: WidgetSnapshot.galleryPreview.reminderCount)
        GalleryCircularCountdownStub(daysUntil: WidgetSnapshot.galleryPreview.nextHostingEvent?.daysUntil ?? 7)
        GalleryRectangularStub(snapshot: .galleryPreview)
        GalleryInlineStub(snapshot: .galleryPreview)
    }
    .padding()
    .background(Color(red: 0.122, green: 0.165, blue: 0.290))
}
