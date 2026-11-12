import SwiftUI
import UIKit

enum EditorialStyle {
    static let paper = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.11, blue: 0.11, alpha: 1)
            : UIColor(red: 0.98, green: 0.98, blue: 0.97, alpha: 1)
    })
    static let ink = Color.primary
    static let blue = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.59, green: 0.76, blue: 0.81, alpha: 1)
            : UIColor(red: 0.29, green: 0.44, blue: 0.49, alpha: 1)
    })

    static func headline(_ size: CGFloat) -> Font {
        .custom("Georgia-Bold", size: size, relativeTo: .largeTitle)
    }
    static func serif(_ size: CGFloat) -> Font {
        .custom("Georgia", size: size, relativeTo: .body)
    }
}
