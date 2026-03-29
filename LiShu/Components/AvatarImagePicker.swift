import SwiftUI
import PhotosUI

struct AvatarImagePicker: View {
    @Binding var imageData: Data?
    var name: String?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            VStack(spacing: 8) {
                ZStack {
                    AvatarView(imageData: imageData, name: name, size: 88)

                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .background(Circle().fill(DesignSystem.Colors.bgPage).frame(width: 22, height: 22))
                        .offset(x: 30, y: 30)
                }

                Text(String(localized: "contact.add.addAvatar"))
                    .font(DesignSystem.Typography.small)
                    .foregroundStyle(DesignSystem.Colors.primary)
            }
        }
        .buttonStyle(.plain)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        imageData = data
                    }
                }
            }
        }
    }
}

#Preview {
    AvatarImagePicker(imageData: .constant(nil), name: "张")
}
