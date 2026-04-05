import PhotosUI
import SwiftUI

struct AvatarImagePicker: View {
    @Binding var imageData: Data?
    var name: String?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                AvatarView(imageData: imageData, name: name, size: 88)
                    .overlay {
                        Circle()
                            .stroke(DesignSystem.Colors.bgSurface, lineWidth: 1)
                    }

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .background(Circle().fill(DesignSystem.Colors.bgPage).frame(width: 22, height: 22))
                    .offset(x: 30, y: 30)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "contact.add.addAvatar"))
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
