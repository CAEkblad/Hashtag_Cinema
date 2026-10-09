import SwiftUI
import TipKit

// Short in-app tips that show once, the first time someone reaches a screen.

struct MarketTip: Tip {
    var title: Text { Text("Ideas for your city") }
    var message: Text? { Text("Open My market for this month's local topics, neighborhood spotlights and an idea pack for every city you serve.") }
    var image: Image? { Image(systemName: "mappin.and.ellipse") }
}

struct NewIdeasTip: Tip {
    var title: Text { Text("Want different ideas?") }
    var message: Text? { Text("Tap New ideas and we write a fresh set for your market. Tap any card for the shot list and script.") }
    var image: Image? { Image(systemName: "sparkles") }
}

struct ReviewTip: Tip {
    var title: Text { Text("Leave notes on the exact second") }
    var message: Text? { Text("Pause the video and add a note. Your editor sees it at that moment in the clip.") }
    var image: Image? { Image(systemName: "text.bubble.fill") }
}

enum CinemaTips {
    static func configure() {
        try? Tips.configure([.displayFrequency(.immediate)])
    }
}
