import SwiftUI

enum MahjongTheme {
    // Board surfaces
    static let tableFelt  = Color(red: 0.18, green: 0.42, blue: 0.26)  // #2E6B42 — classic felt green
    static let feltDark   = Color(red: 0.12, green: 0.28, blue: 0.17)  // darker felt for board background

    // Player tiles — dark glass cards sitting on the green board
    static let tileBackground       = Color(white: 0.10, opacity: 0.72)
    static let dealerTileBackground = Color(red: 0.45, green: 0.32, blue: 0.06, opacity: 0.80)  // dark amber
    static let dealerBorderColor    = Color(red: 0.90, green: 0.72, blue: 0.22)  // gold

    // Center info box
    static let centerCardBackground = Color(white: 0.08, opacity: 0.88)

    // Text on dark tiles / cards
    static let primaryText   = Color.white
    static let secondaryText = Color.white.opacity(0.65)
    static let dealerText    = Color(red: 1.0, green: 0.85, blue: 0.35)  // bright gold
}
