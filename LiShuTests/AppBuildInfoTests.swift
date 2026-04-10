import Foundation
@testable import LiShu
import Testing

struct AppBuildInfoTests {
    @Test("sandbox receipt is treated as TestFlight on device builds")
    func sandboxReceiptEnablesTestFlightBuild() {
        let receiptURL = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/appStoreReceipt/sandboxReceipt")

        #expect(
            AppBuildInfo.isTestFlightBuild(
                appStoreReceiptURL: receiptURL,
                isSimulator: false,
                isPreview: false
            )
        )
    }

    @Test("simulator never counts as TestFlight")
    func simulatorDisablesTestFlightBuild() {
        let receiptURL = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/appStoreReceipt/sandboxReceipt")

        #expect(
            AppBuildInfo.isTestFlightBuild(
                appStoreReceiptURL: receiptURL,
                isSimulator: true,
                isPreview: false
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
                isPreview: true
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
                isPreview: false
            ) == false
        )
    }
}
