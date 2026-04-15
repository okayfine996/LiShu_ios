import CoreGraphics
import Foundation
@testable import LiShu
import Testing

@Suite(.serialized)
struct SyntheticLedgerSampleAuditTests {
    private let pipeline = LedgerHeuristicPipeline.shared
    private let service = OCRService.shared

    @Test func syntheticLedgerSamplesMatchExpectedEntries() {
        for sample in SyntheticLedgerFixtures.samples {
            let result = pipeline.process(lines: sample.lines, service: service)
            let items = pipeline.auditItems(
                pipeline.extractHeuristicItems(result.candidates, service: service),
                service: service
            )

            for expected in sample.expectedEntries where expected.expectedFlag != .reject {
                #expect(
                    items.contains { item in
                        item.name == expected.name && item.amount == expected.amount
                    },
                    Comment("Missing expected entry in \(sample.sampleID): \(expected.name) \(expected.amount)")
                )
            }

            for rejected in sample.expectedEntries where rejected.expectedFlag == .reject {
                #expect(
                    !items.contains { item in
                        item.name == rejected.name && item.amount == rejected.amount && item.confidence == .high
                    },
                    Comment("Rejected entry should not be treated as high confidence in \(sample.sampleID)")
                )
            }

            if !sample.expectedIgnoredText.isEmpty {
                #expect(
                    result.filteredNoiseCount >= sample.expectedIgnoredText.count,
                    Comment("Noise filtering count too low in \(sample.sampleID)")
                )
            }

            if let expectedEventName = sample.expectedEventName {
                #expect(
                    items.contains(where: { $0.eventName == expectedEventName }),
                    Comment("Expected event hint missing in \(sample.sampleID)")
                )
            }

            if let expectedEntryCount = sample.expectedEntryCount {
                #expect(
                    items.count == expectedEntryCount,
                    Comment("Unexpected extracted item count in \(sample.sampleID)")
                )
            }
        }
    }
}

private enum SyntheticLedgerFixtures {
    static let samples: [SyntheticLedgerSample] = [
        SyntheticLedgerSample(
            sampleID: "synthetic_001",
            lines: [
                line("礼簿", x: 0.18, y: 0.95, width: 0.22),
                line("张三 500", x: 0.12, y: 0.86, width: 0.34),
                line("李四 800", x: 0.12, y: 0.80, width: 0.34),
            ],
            expectedEntries: [
                .init(name: "张三", amount: 500, expectedFlag: .pass),
                .init(name: "李四", amount: 800, expectedFlag: .pass),
            ],
            expectedIgnoredText: ["礼簿"]
        ),
        SyntheticLedgerSample(
            sampleID: "synthetic_002",
            lines: [
                line("500 王五", x: 0.12, y: 0.87, width: 0.34),
                line("1200 赵六", x: 0.12, y: 0.81, width: 0.38),
            ],
            expectedEntries: [
                .init(name: "王五", amount: 500, expectedFlag: .pass),
                .init(name: "赵六", amount: 1200, expectedFlag: .pass),
            ]
        ),
        SyntheticLedgerSample(
            sampleID: "synthetic_003",
            lines: [
                line("陈七", x: 0.12, y: 0.86, width: 0.12),
                line("600", x: 0.63, y: 0.86, width: 0.10),
                line("孙八", x: 0.12, y: 0.80, width: 0.12),
                line("900", x: 0.63, y: 0.80, width: 0.10),
            ],
            expectedEntries: [
                .init(name: "陈七", amount: 600, expectedFlag: .pass),
                .init(name: "孙八", amount: 900, expectedFlag: .pass),
            ]
        ),
        SyntheticLedgerSample(
            sampleID: "synthetic_004",
            lines: [
                line("周九", x: 0.14, y: 0.86, width: 0.12),
                line("700", x: 0.14, y: 0.825, width: 0.10),
                line("吴十", x: 0.14, y: 0.76, width: 0.12),
                line("1000", x: 0.14, y: 0.725, width: 0.12),
            ],
            expectedEntries: [
                .init(name: "周九", amount: 700, expectedFlag: .pass),
                .init(name: "吴十", amount: 1000, expectedFlag: .pass),
            ]
        ),
        SyntheticLedgerSample(
            sampleID: "synthetic_005",
            lines: [
                line("礼簿", x: 0.18, y: 0.96, width: 0.22),
                line("第2页", x: 0.72, y: 0.96, width: 0.12),
                line("张三 500", x: 0.12, y: 0.85, width: 0.34),
                line("李四 800", x: 0.12, y: 0.79, width: 0.34),
                line("合计 1300", x: 0.12, y: 0.70, width: 0.34),
            ],
            expectedEntries: [
                .init(name: "张三", amount: 500, expectedFlag: .pass),
                .init(name: "李四", amount: 800, expectedFlag: .pass),
            ],
            expectedIgnoredText: ["礼簿", "第2页", "合计 1300"]
        ),
        SyntheticLedgerSample(
            sampleID: "synthetic_006",
            lines: [
                line("王五 O0O", x: 0.12, y: 0.86, width: 0.34),
                line("李四 1S00", x: 0.12, y: 0.80, width: 0.34),
            ],
            expectedEntries: [
                .init(name: "王五", amount: 0, expectedFlag: .reject),
                .init(name: "李四", amount: 1500, expectedFlag: .needsReview),
            ]
        ),
        SyntheticLedgerSample(
            sampleID: "synthetic_007",
            lines: [
                line("婚宴礼簿", x: 0.18, y: 0.95, width: 0.24),
                line("张三 600", x: 0.12, y: 0.86, width: 0.34),
            ],
            expectedEntries: [
                .init(name: "张三", amount: 600, expectedFlag: .pass),
            ],
            expectedIgnoredText: ["婚宴礼簿"],
            expectedEventName: EventType.wedding.displayName
        ),
        SyntheticLedgerSample(
            sampleID: "synthetic_008",
            lines: [
                line("13800138000", x: 0.12, y: 0.92, width: 0.24),
                line("幸福路88号", x: 0.12, y: 0.87, width: 0.24),
                line("王五 900", x: 0.12, y: 0.79, width: 0.34),
            ],
            expectedEntries: [
                .init(name: "王五", amount: 900, expectedFlag: .pass),
            ],
            expectedIgnoredText: ["13800138000", "幸福路88号"]
        ),
        SyntheticLedgerSample(
            sampleID: "synthetic_009",
            lines: [
                line("赵六 ￥1,200", x: 0.12, y: 0.85, width: 0.38),
                line("孙八 ¥2,600", x: 0.12, y: 0.79, width: 0.38),
            ],
            expectedEntries: [
                .init(name: "赵六", amount: 1200, expectedFlag: .pass),
                .init(name: "孙八", amount: 2600, expectedFlag: .pass),
            ]
        ),
        SyntheticLedgerSample(
            sampleID: "synthetic_010",
            lines: [
                line("张三", x: 0.12, y: 0.86, width: 0.12),
                line("500", x: 0.63, y: 0.825, width: 0.10),
                line("李四", x: 0.12, y: 0.77, width: 0.12),
                line("800", x: 0.63, y: 0.735, width: 0.10),
            ],
            expectedEntries: [],
            expectedEntryCount: 0
        ),
        SyntheticLedgerSample(
            sampleID: "synthetic_011",
            lines: [
                line("周九 ８８８", x: 0.12, y: 0.84, width: 0.34),
            ],
            expectedEntries: [
                .init(name: "周九", amount: 888, expectedFlag: .pass),
            ]
        ),
        SyntheticLedgerSample(
            sampleID: "synthetic_012",
            lines: [
                line("来宾名单", x: 0.16, y: 0.96, width: 0.24),
                line("第3页", x: 0.72, y: 0.96, width: 0.10),
                line("陈七 5O0", x: 0.12, y: 0.86, width: 0.34),
                line("13812345678", x: 0.12, y: 0.80, width: 0.24),
                line("吴十 1000", x: 0.12, y: 0.74, width: 0.34),
            ],
            expectedEntries: [
                .init(name: "陈七", amount: 500, expectedFlag: .needsReview),
                .init(name: "吴十", amount: 1000, expectedFlag: .pass),
            ],
            expectedIgnoredText: ["来宾名单", "第3页", "13812345678"]
        ),
    ]

    private static func line(
        _ text: String,
        confidence: Float = 0.9,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat = 0.04,
        pageIndex: Int = 0
    ) -> LedgerOCRLine {
        LedgerOCRLine(
            text: text,
            confidence: confidence,
            boundingBox: CGRect(x: x, y: y, width: width, height: height),
            pageIndex: pageIndex
        )
    }
}

private struct SyntheticLedgerSample {
    let sampleID: String
    let lines: [LedgerOCRLine]
    let expectedEntries: [SyntheticExpectedEntry]
    var expectedIgnoredText: [String] = []
    var expectedEventName: String?
    var expectedEntryCount: Int?
}

private struct SyntheticExpectedEntry {
    enum ExpectedFlag {
        case pass
        case needsReview
        case reject
    }

    let name: String
    let amount: Double
    let expectedFlag: ExpectedFlag
}
