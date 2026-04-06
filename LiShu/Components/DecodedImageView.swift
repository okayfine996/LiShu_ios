import SwiftUI

struct DecodedImageView: View {
    let data: Data
    let maxPixelSize: Int

    var body: some View {
        Group {
            if let uiImage = ImagePipeline.image(from: data, maxPixelSize: maxPixelSize) {
                Image(uiImage: uiImage)
                    .resizable()
            }
        }
    }
}
