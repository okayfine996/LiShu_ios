import Foundation
import Testing
@testable import LiShu

struct RelationshipTagsTests {

    @Test("allCases contains exactly 3 values")
    func testAllCases() {
        #expect(RelationshipCategory.allCases.count == 3)
        #expect(RelationshipCategory.allCases.contains(.family))
        #expect(RelationshipCategory.allCases.contains(.relative))
        #expect(RelationshipCategory.allCases.contains(.social))
    }

    @Test("circle mapping: family=1, relative=2, social=3")
    func testCircleMapping() {
        #expect(RelationshipCategory.family.circle == 1)
        #expect(RelationshipCategory.relative.circle == 2)
        #expect(RelationshipCategory.social.circle == 3)
    }

    @Test("each category has a unique SF Symbol icon")
    func testIconMapping() {
        let familyIcon = RelationshipCategory.family.icon
        let relativeIcon = RelationshipCategory.relative.icon
        let socialIcon = RelationshipCategory.social.icon

        #expect(!familyIcon.isEmpty)
        #expect(!relativeIcon.isEmpty)
        #expect(!socialIcon.isEmpty)
        #expect(familyIcon != relativeIcon)
        #expect(relativeIcon != socialIcon)
    }

    @Test("each category has non-empty tags array")
    func testTagsNotEmpty() {
        for category in RelationshipCategory.allCases {
            #expect(!category.tags.isEmpty, "\(category) should have tags")
        }
    }

    @Test("family tags contain expected members")
    func testFamilyTags() {
        let tags = RelationshipCategory.family.tags
        #expect(tags.contains("父亲"))
        #expect(tags.contains("母亲"))
        #expect(tags.contains("配偶"))
    }

    @Test("Codable round-trip preserves value")
    func testCodable() throws {
        let original = RelationshipCategory.relative
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RelationshipCategory.self, from: data)
        #expect(decoded == original)
        #expect(decoded.rawValue == "亲戚")
    }
}
