import SwiftUI
import WidgetKit

@main
struct LiShuWidgetBundle: WidgetBundle {
    var body: some Widget {
        LiShuHomeWidget()
        LiShuCountdownWidget()
        LiShuFinancialWidget()
        LiShuMediumEventWidget()
        LiShuMediumFinancialWidget()
        LiShuCircularCountdownWidget()
    }
}
