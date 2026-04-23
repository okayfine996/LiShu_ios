import SwiftUI

extension View {
    /// For form/task sheets (data entry with an explicit save action): Cancel text, leading toolbar.
    func sheetCancelButton(action: @escaping () -> Void) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(String(localized: "common.cancel"), action: action)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }

    /// For info/standalone sheets (no explicit save action): X icon, trailing toolbar.
    func sheetCloseButton(action: @escaping () -> Void) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: action) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
        }
    }
}
