import SwiftUI

struct EventCoverView: View {
    let coverImage: Data?
    let eventType: EventType
    var size: CGFloat = 48
    /// 无封面图时的底色（有图时仍使用 `bgIconSubtle` 作为图片衬底）
    var placeholderBackground: Color = DesignSystem.Colors.bgIconSubtle

    private var hasImage: Bool {
        if let data = coverImage, UIImage(data: data) != nil { return true }
        return false
    }

    var body: some View {
        Group {
            if let data = coverImage, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: eventType.iconName)
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }
        }
        .frame(width: size, height: size)
        .background(hasImage ? DesignSystem.Colors.bgIconSubtle : placeholderBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
    }
}

#Preview {
    VStack(spacing: 16) {
        EventCoverView(coverImage: nil, eventType: .wedding)
        EventCoverView(coverImage: nil, eventType: .birthday)
        EventCoverView(coverImage: nil, eventType: .festival, size: 64)
    }
}
