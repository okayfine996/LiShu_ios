import SwiftUI

struct OCRImportStateContainer: View {
    let processingState: LoadingState<[OCRRecordItem]>
    let isAIEnhanced: Bool
    @Bindable var viewModel: OCRImportViewModel
    let onOpenCamera: () -> Void
    let onOpenAlbum: () -> Void
    let onRetry: () -> Void

    var body: some View {
        Group {
            switch processingState {
            case .idle:
                OCRImportSourceSelectionView(
                    onOpenCamera: onOpenCamera,
                    onOpenAlbum: onOpenAlbum
                )
            case .loading:
                OCRImportProcessingView(isAIEnhanced: isAIEnhanced)
            case .loaded:
                OCRResultView(viewModel: viewModel)
            case let .error(message):
                OCRImportErrorView(message: message, onRetry: onRetry)
            }
        }
    }
}

struct OCRImportSourceSelectionView: View {
    let onOpenCamera: () -> Void
    let onOpenAlbum: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 56))
                    .foregroundStyle(DesignSystem.Colors.primary)

                VStack(spacing: 8) {
                    Text(String(localized: "ocr.source.title"))
                        .font(DesignSystem.Typography.title2)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(String(localized: "ocr.source.subtitle"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Button(action: onOpenCamera) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                            Text(String(localized: "ocr.source.camera"))
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button(action: onOpenAlbum) {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 18))
                            Text(String(localized: "ocr.source.album"))
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .navigationTitle(String(localized: "ocr.import.title"))
    }
}

struct OCRImportProcessingView: View {
    let isAIEnhanced: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if isAIEnhanced {
                AISparkleIcon()
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(DesignSystem.Colors.primary)
            }

            Text(isAIEnhanced ? String(localized: "ocr.ai.processing") : String(localized: "ocr.import.processing"))
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(String(localized: "ocr.import.processingHint"))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(String(localized: "ocr.import.title"))
    }
}

struct OCRImportErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.primary)

            Text(String(localized: "ocr.error.title"))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(message)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: onRetry) {
                Text(String(localized: "ocr.error.retry"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)

            Spacer()
        }
        .navigationTitle(String(localized: "ocr.import.title"))
    }
}
