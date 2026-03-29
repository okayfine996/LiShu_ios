import SwiftUI

struct EventCoverView: View {
    let coverImage: Data?
    let eventType: EventType
    var size: CGFloat = 48

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
        .background(DesignSystem.Colors.bgIconSubtle)
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
