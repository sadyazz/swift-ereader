import WidgetKit
import SwiftUI

@main
struct swift_ereader_widgetBundle: WidgetBundle {
    var body: some Widget {
        ReadingStatsWidget()
        StreakWidget()
    }
}
