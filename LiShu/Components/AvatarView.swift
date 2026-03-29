import SwiftUI

struct AvatarView: View {
    let imageData: Data?
    var name: String?
    var size: CGFloat = 44

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
        .background(DesignSystem.Colors.bgIconSubtle)
        .clipShape(Circle())
    }
}

#Preview {
    VStack(spacing: 16) {
        AvatarView(imageData: nil, name: "张三", size: 88)
        AvatarView(imageData: nil, name: "李四", size: 48)
        AvatarView(imageData: nil, size: 44)
    }
}
