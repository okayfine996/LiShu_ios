import SwiftUI

struct AvatarView: View {
    let imageData: Data?
    var name: String?
    var size: CGFloat = DesignSystem.Layout.avatarM
    /// 无头像图片时的底色（有图时仍使用 `bgIconSubtle` 作为照片衬底）
    var placeholderBackground: Color = DesignSystem.Colors.bgIconSubtle

    private var hasImage: Bool {
        if let data = imageData, UIImage(data: data) != nil { return true }
        return false
    }

    var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let firstChar = name?.first {
                Text(String(firstChar))
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.primary)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(width: size, height: size)
        .background(hasImage ? DesignSystem.Colors.bgIconSubtle : placeholderBackground)
        .clipShape(Circle())
    }
}

#Preview {
    VStack(spacing: 16) {
        AvatarView(imageData: nil, name: "张三", size: 88)
        AvatarView(imageData: nil, name: "李四")
        AvatarView(imageData: nil)
    }
}
