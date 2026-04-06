import SwiftUI

struct EventCoverView: View {
    let coverImage: Data?
    let eventType: EventType
    var size: CGFloat = DesignSystem.Layout.avatarM
    /// 无封面图时的底色（有图时仍使用 `bgIconSubtle` 作为图片衬底）
    var placeholderBackground: Color = DesignSystem.Colors.bgIconSubtle

    private var coverPixelSize: Int {
        ImagePipeline.pixelSize(for: size)
    }

    private var decodedImageAvailable: Bool {
        guard let data = coverImage else { return false }
        return ImagePipeline.image(from: data, maxPixelSize: coverPixelSize) != nil
    }

    var body: some View {
        Group {
            if let data = coverImage, decodedImageAvailable {
                DecodedImageView(data: data, maxPixelSize: coverPixelSize)
                    .scaledToFill()
            } else {
                Image(systemName: eventType.iconName)
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }
        }
        .frame(width: size, height: size)
        .background(decodedImageAvailable ? DesignSystem.Colors.bgIconSubtle : placeholderBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
    }
}

#Preview {
    VStack(spacing: 16) {
        EventCoverView(coverImage: nil, eventType: .wedding)
        EventCoverView(coverImage: nil, eventType: .birthday)
        EventCoverView(coverImage: nil, eventType: .festival, size: DesignSystem.Layout.avatarM + 8)
    }
}
