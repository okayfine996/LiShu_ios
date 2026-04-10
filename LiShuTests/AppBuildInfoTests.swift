import Foundation
@testable import LiShu
import Testing

struct AppBuildInfoTests {
    @Test("sandbox receipt without embedded provision counts as TestFlight")
    func sandboxReceiptWithoutProvisionEnablesTestFlightBuild() {
        let receiptURL = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/appStoreReceipt/sandboxReceipt")

        #expect(
            AppBuildInfo.isTestFlightBuild(
                appStoreReceiptURL: receiptURL,
                isSimulator: false,
                isPreview: false,
                hasEmbeddedProvision: false
            )
        )
    }

    @Test("sandbox receipt with embedded provision does not count as TestFlight")
    func sandboxReceiptWithProvisionDisablesTestFlightBuild() {
        let receiptURL = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/appStoreReceipt/sandboxReceipt")

        #expect(
            AppBuildInfo.isTestFlightBuild(
                appStoreReceiptURL: receiptURL,
                isSimulator: false,
                isPreview: false,
                hasEmbeddedProvision: true
            ) == false
        )
    }

    @Test("simulator never counts as TestFlight")
    func simulatorDisablesTestFlightBuild() {
        let receiptURL = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/appStoreReceipt/sandboxReceipt")

        #expect(
            AppBuildInfo.isTestFlightBuild(
                appStoreReceiptURL: receiptURL,
                isSimulator: true,
                isPreview: false,
                hasEmbeddedProvision: false
            ) == false
        )
    }

    @Test("preview never counts as TestFlight")
    func previewDisablesTestFlightBuild() {
        let receiptURL = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/appStoreReceipt/sandboxReceipt")

        #expect(
            AppBuildInfo.isTestFlightBuild(
                appStoreReceiptURL: receiptURL,
                isSimulator: false,
                isPreview: true,
                hasEmbeddedProvision: false
            ) == false
        )
    }

    @Test("production receipt does not count as TestFlight")
    func productionReceiptDisablesTestFlightBuild() {
        let receiptURL = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/appStoreReceipt/receipt")

        #expect(
            AppBuildInfo.isTestFlightBuild(
                appStoreReceiptURL: receiptURL,
                isSimulator: false,
                isPreview: false,
                hasEmbeddedProvision: false
            ) == false
        )
    }
}
