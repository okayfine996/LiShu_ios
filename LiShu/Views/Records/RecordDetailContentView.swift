import SwiftData
import SwiftUI

struct RecordDetailContentView: View {
    let record: Record
    let directionLabel: String
    let paymentMethodName: String
    let contactRecordCount: Int
    let contactNetAmount: Double
    let formattedDate: String
    let shouldShowReturnButton: Bool
    let onReturnTap: () -> Void
    let onPhotoTap: (Data) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    RecordDetailHeroSection(record: record, directionLabel: directionLabel)
                    RecordDetailAmountSection(record: record)
                    RecordDetailTypeSummarySection(record: record)
                    RecordDetailInfoCard(
                        record: record,
                        paymentMethodName: paymentMethodName,
                        formattedDate: formattedDate
                    )
                    RecordDetailNotesSection(note: record.note)
                    RecordDetailPhotosSection(photos: sortedPhotos, onPhotoTap: onPhotoTap)
                    RecordDetailContactHistorySection(
                        contact: record.contact,
                        contactRecordCount: contactRecordCount,
                        contactNetAmount: contactNetAmount
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .padding(.bottom, 80)
            }

            if shouldShowReturnButton {
                RecordDetailReturnButton(action: onReturnTap)
            }
        }
    }

    private var sortedPhotos: [RecordPhoto] {
        (record.photos ?? []).sorted { $0.createdAt < $1.createdAt }
    }
}
