import Foundation
@testable import LiShu
import Testing

struct DeepLinkRouterTests {
    // MARK: - Valid links

    @Test func homeLink() throws {
        let url = try #require(URL(string: "lishu://home"))
        #expect(DeepLink.from(url) == .home)
    }

    @Test func addRecordLink() throws {
        let url = try #require(URL(string: "lishu://add-record"))
        #expect(DeepLink.from(url) == .addRecord)
    }

    @Test func addRecordForEventLink() throws {
        let url = try #require(URL(string: "lishu://add-record?event=abc123"))
        #expect(DeepLink.from(url) == .addRecordForEvent(stableID: "abc123"))
    }

    @Test func giveGiftForEventLink() throws {
        let url = try #require(URL(string: "lishu://add-record?event=abc123&direction=given"))
        #expect(DeepLink.from(url) == .giveGiftForEvent(stableID: "abc123"))
    }

    @Test func addRecordForEventIgnoresUnknownDirection() throws {
        let url = try #require(URL(string: "lishu://add-record?event=abc123&direction=unknown"))
        #expect(DeepLink.from(url) == .addRecordForEvent(stableID: "abc123"))
    }

    @Test func eventDetailLink() throws {
        let url = try #require(URL(string: "lishu://event?id=abc123"))
        #expect(DeepLink.from(url) == .eventDetail(stableID: "abc123"))
    }

    @Test func contactDetailLink() throws {
        let url = try #require(URL(string: "lishu://contact?id=xyz789"))
        #expect(DeepLink.from(url) == .contactDetail(stableID: "xyz789"))
    }

    // MARK: - Invalid links → nil

    @Test func wrongSchemeReturnsNil() throws {
        let url = try #require(URL(string: "https://home"))
        #expect(DeepLink.from(url) == nil)
    }

    @Test func unknownHostReturnsNil() throws {
        let url = try #require(URL(string: "lishu://unknown"))
        #expect(DeepLink.from(url) == nil)
    }

    @Test func eventMissingIDReturnsNil() throws {
        let url = try #require(URL(string: "lishu://event"))
        #expect(DeepLink.from(url) == nil)
    }

    @Test func contactMissingIDReturnsNil() throws {
        let url = try #require(URL(string: "lishu://contact"))
        #expect(DeepLink.from(url) == nil)
    }
}
