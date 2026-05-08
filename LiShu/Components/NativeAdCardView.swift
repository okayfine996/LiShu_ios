import GoogleMobileAds
import SwiftUI

// MARK: - Native Ad Overlay Modifier

struct NativeAdOverlayModifier: ViewModifier {
    @Bindable var adManager: AdManager
    var onDismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay {
                if adManager.showNativeAdOverlay, let nativeAd = adManager.nativeAd {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                adManager.dismissNativeAd()
                            }

                        VStack(spacing: 16) {
                            NativeAdCardRepresentable(nativeAd: nativeAd)
                                .frame(
                                    width: UIScreen.main.bounds.width - 64,
                                    height: 400
                                )
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 20)
                                )
                                .shadow(
                                    color: .black.opacity(0.2),
                                    radius: 20, y: 10
                                )
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        adManager.dismissNativeAd()
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 26, height: 26)
                                            .background(
                                                Color.black.opacity(0.4),
                                                in: Circle()
                                            )
                                    }
                                    .padding(10)
                                }

                            Button {
                                adManager.dismissNativeAd()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12))
                                    Text(String(localized: "ad.upgradePro"))
                                        .font(DesignSystem.Typography.caption)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    Color.white.opacity(0.2),
                                    in: Capsule()
                                )
                            }
                        }
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                    .animation(
                        .spring(duration: 0.35),
                        value: adManager.showNativeAdOverlay
                    )
                }
            }
            .animation(
                .easeInOut(duration: 0.25),
                value: adManager.showNativeAdOverlay
            )
    }
}

extension View {
    func nativeAdOverlay(
        adManager: AdManager,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(
            NativeAdOverlayModifier(adManager: adManager, onDismiss: onDismiss)
        )
    }
}

// MARK: - GADNativeAdView 桥接（只做容器，素材原样展示）

private struct NativeAdCardRepresentable: UIViewRepresentable {
    let nativeAd: NativeAd

    func makeUIView(context _: Context) -> NativeAdView {
        let nativeAdView = NativeAdView()
        nativeAdView.backgroundColor = UIColor(DesignSystem.Colors.bgSurface)
        nativeAdView.layer.cornerRadius = 20
        nativeAdView.clipsToBounds = true

        // 媒体
        let mediaView = MediaView()
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(mediaView)
        nativeAdView.mediaView = mediaView

        // 图标
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        iconView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(iconView)
        nativeAdView.iconView = iconView

        // 广告主
        let advertiserLabel = UILabel()
        advertiserLabel.font = .systemFont(ofSize: 11, weight: .medium)
        advertiserLabel.textColor = UIColor(DesignSystem.Colors.textTertiary)
        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(advertiserLabel)
        nativeAdView.advertiserView = advertiserLabel

        // 标题
        let headlineLabel = UILabel()
        headlineLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        headlineLabel.textColor = UIColor(DesignSystem.Colors.textPrimary)
        headlineLabel.numberOfLines = 2
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(headlineLabel)
        nativeAdView.headlineView = headlineLabel

        // 描述
        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 13, weight: .regular)
        bodyLabel.textColor = UIColor(DesignSystem.Colors.textSecondary)
        bodyLabel.numberOfLines = 2
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(bodyLabel)
        nativeAdView.bodyView = bodyLabel

        // 广告标签
        let badge = UILabel()
        badge.text = "Ad"
        badge.font = .systemFont(ofSize: 9, weight: .bold)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.backgroundColor = UIColor(DesignSystem.Colors.accentGold)
        badge.layer.cornerRadius = 4
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(badge)

        let p: CGFloat = 16

        NSLayoutConstraint.activate([
            // 媒体 - 上半部
            mediaView.topAnchor.constraint(equalTo: nativeAdView.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            mediaView.heightAnchor.constraint(equalTo: nativeAdView.heightAnchor, multiplier: 0.5),

            // 图标
            iconView.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: p),
            iconView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: p),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            // Ad badge
            badge.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: p),
            badge.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            badge.widthAnchor.constraint(equalToConstant: 22),
            badge.heightAnchor.constraint(equalToConstant: 14),

            // 广告主 - icon 右侧
            advertiserLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            advertiserLabel.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 4),
            advertiserLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: nativeAdView.trailingAnchor, constant: -p
            ),

            // 标题
            headlineLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            headlineLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: p),
            headlineLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -p),

            // 描述
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
            bodyLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: p),
            bodyLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -p),

            // 描述底部留白
            bodyLabel.bottomAnchor.constraint(lessThanOrEqualTo: nativeAdView.bottomAnchor, constant: -p),
        ])

        return nativeAdView
    }

    func updateUIView(_ nativeAdView: NativeAdView, context _: Context) {
        nativeAdView.nativeAd = nativeAd

        // 媒体
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent

        // 图标
        if let iconImageView = nativeAdView.iconView as? UIImageView {
            iconImageView.image = nativeAd.icon?.image
            iconImageView.isHidden = nativeAd.icon == nil
        }

        // 广告主
        if let label = nativeAdView.advertiserView as? UILabel {
            label.text = nativeAd.advertiser
            label.isHidden = nativeAd.advertiser == nil
        }

        // 标题
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline

        // 描述
        if let label = nativeAdView.bodyView as? UILabel {
            label.text = nativeAd.body
            label.isHidden = nativeAd.body == nil
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        Text(String(localized: "common.preview.unavailable"))
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
    }
}
