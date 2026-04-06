import Foundation
@testable import LiShu
import Testing

struct ImagePipelineTests {
    @Test func optimizedJPEGDataDownsizesLargeInput() throws {
        let input = SampleImages.makePNGData(width: 3000, height: 2000)

        let output = ImagePipeline.optimizedJPEGData(
            from: input,
            maxPixelSize: 600,
            compressionQuality: 0.8
        )

        let optimizedData = try #require(output)
        let dimensions = try #require(ImagePipeline.imageDimensions(from: optimizedData))
        #expect(dimensions.width <= 600)
        #expect(dimensions.height <= 600)
    }

    @Test func optimizedJPEGDataDoesNotUpscaleSmallInput() throws {
        let input = SampleImages.makePNGData(width: 120, height: 90)

        let output = ImagePipeline.optimizedJPEGData(
            from: input,
            maxPixelSize: 600,
            compressionQuality: 0.8
        )

        let optimizedData = try #require(output)
        let dimensions = try #require(ImagePipeline.imageDimensions(from: optimizedData))
        #expect(dimensions.width <= 120)
        #expect(dimensions.height <= 90)
    }

    @Test func imageCacheReturnsStableUIImageInstance() throws {
        let input = SampleImages.makePNGData(width: 1200, height: 800)
        let first = try #require(ImagePipeline.image(from: input, maxPixelSize: 300))
        let second = try #require(ImagePipeline.image(from: input, maxPixelSize: 300))

        #expect(first === second)
    }

    @Test func invalidImageDataReturnsNil() {
        let invalid = Data("not-an-image".utf8)
        #expect(ImagePipeline.image(from: invalid, maxPixelSize: 120) == nil)
        #expect(ImagePipeline.optimizedJPEGData(from: invalid, maxPixelSize: 120, compressionQuality: 0.8) == nil)
    }
}
