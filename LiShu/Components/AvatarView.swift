import SwiftUI

struct AvatarView: View {
    let imageData: Data?
    var name: String?
    var size: CGFloat = DesignSystem.Layout.avatarM
    /// 无头像图片时的底色（有图时仍使用 `bgIconSubtle` 作为照片衬底）
    var placeholderBackground: Color = DesignSystem.Colors.bgIconSubtle

    private var avatarPixelSize: Int {
        ImagePipeline.pixelSize(for: size)
    }

    private var decodedImageAvailable: Bool {
        guard let data = imageData else { return false }
        return ImagePipeline.image(from: data, maxPixelSize: avatarPixelSize) != nil
    }

    var body: some View {
        Group {
            if let data = imageData, decodedImageAvailable {
                DecodedImageView(data: data, maxPixelSize: avatarPixelSize)
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
        .background(decodedImageAvailable ? DesignSystem.Colors.bgIconSubtle : placeholderBackground)
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
