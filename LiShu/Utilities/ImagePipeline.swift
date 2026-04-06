import Foundation
import ImageIO
import UIKit

enum ImagePipeline {
    private static let imageCache = NSCache<NSString, UIImage>()

    enum Preset {
        static let avatarMaxPixelSize = 256
        static let eventCoverMaxPixelSize = 1600
        static let recordPhotoMaxPixelSize = 1800
        static let ocrInputMaxPixelSize = 2200
        static let homeHeroMaxPixelSize = 1200
        static let detailHeroMaxPixelSize = 1400
        static let thumbnailMaxPixelSize = 240
    }

    static func image(from data: Data, maxPixelSize: Int) -> UIImage? {
        let cacheKey = cacheKey(for: data, maxPixelSize: maxPixelSize)
        if let cachedImage = imageCache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }

        guard let decodedImage = downsampledImage(from: data, maxPixelSize: maxPixelSize) else {
            return nil
        }

        imageCache.setObject(decodedImage, forKey: cacheKey as NSString)
        return decodedImage
    }

    static func optimizedJPEGData(from data: Data, maxPixelSize: Int, compressionQuality: CGFloat) -> Data? {
        guard let image = downsampledImage(from: data, maxPixelSize: maxPixelSize) else {
            return nil
        }
        return optimizedJPEGData(from: image, maxPixelSize: maxPixelSize, compressionQuality: compressionQuality)
    }

    static func optimizedJPEGData(from image: UIImage, maxPixelSize: Int, compressionQuality: CGFloat) -> Data? {
        let resizedImage = resizedImageIfNeeded(image, maxPixelSize: maxPixelSize)
        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }

    static func pixelSize(for points: CGFloat, scale: CGFloat = UIScreen.main.scale) -> Int {
        max(Int(ceil(points * scale)), 1)
    }

    static func pixelSize(for size: CGSize, scale: CGFloat = UIScreen.main.scale) -> Int {
        max(Int(ceil(max(size.width, size.height) * scale)), 1)
    }

    static func imageDimensions(from data: Data) -> CGSize? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let pixelWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let pixelHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat
        else {
            return nil
        }

        return CGSize(width: pixelWidth, height: pixelHeight)
    }

    static func clearCache() {
        imageCache.removeAllObjects()
    }

    private static func cacheKey(for data: Data, maxPixelSize: Int) -> String {
        let digestPrefix = data.prefix(32).map { String(format: "%02x", $0) }.joined()
        return "\(data.count)-\(maxPixelSize)-\(digestPrefix)"
    }

    private static func downsampledImage(from data: Data, maxPixelSize: Int) -> UIImage? {
        guard maxPixelSize > 0,
              let source = CGImageSourceCreateWithData(data as CFData, nil)
        else {
            return UIImage(data: data)
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]

        if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
            return UIImage(cgImage: cgImage)
        }

        return UIImage(data: data)
    }

    private static func resizedImageIfNeeded(_ image: UIImage, maxPixelSize: Int) -> UIImage {
        let maxDimension = max(image.size.width, image.size.height)
        guard maxDimension > CGFloat(maxPixelSize), maxDimension > 0 else {
            return image
        }

        let ratio = CGFloat(maxPixelSize) / maxDimension
        let targetSize = CGSize(
            width: max(image.size.width * ratio, 1),
            height: max(image.size.height * ratio, 1)
        )
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
