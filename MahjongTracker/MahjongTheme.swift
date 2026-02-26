import SwiftUI

enum MahjongTheme {
    // Board surfaces
    static let tableFelt  = Color(red: 0.18, green: 0.42, blue: 0.26)  // #2E6B42 — classic felt green
    static let feltDark   = Color(red: 0.12, green: 0.28, blue: 0.17)  // darker felt for board background
    static let panelDark  = Color(white: 0.13)                          // neutral dark gray for utility sheets
    static let feltDeeper = Color(red: 0.07, green: 0.16, blue: 0.10)  // deep felt — content area behind the header

    // Player tiles — dark glass cards sitting on the green board
    static let tileBackground       = Color(white: 0.10, opacity: 0.72)
    static let dealerTileBackground = Color(red: 0.45, green: 0.32, blue: 0.06, opacity: 0.80)  // dark amber
    static let dealerBorderColor    = Color(red: 0.90, green: 0.72, blue: 0.22)  // gold

    // Center info box
    static let centerCardBackground = Color(white: 0.08, opacity: 0.88)

    // Text on dark tiles / cards
    static let primaryText   = Color.white
    static let secondaryText = Color.white.opacity(0.85)
    static let dealerText    = Color(red: 1.0, green: 0.85, blue: 0.35)  // bright gold

    // MARK: - Typography

    enum Font {
        static let windCharacter = SwiftUI.Font.system(size: 40, weight: .bold)
        static let splashHero    = SwiftUI.Font.system(size: 52, weight: .black)
        static let tileEmoji     = SwiftUI.Font.system(size: 50)
    }

    // MARK: - Corner Radii

    enum Radius {
        static let playerButton:    CGFloat = 6
        static let pickerContainer: CGFloat = 9
        static let tile:            CGFloat = 10
        static let profileCard:     CGFloat = 12
        static let centerBox:       CGFloat = 14
        static let gameOverCard:    CGFloat = 20
    }

    // MARK: - Opacities

    enum Opacity {
        static let tileBorder:       Double = 0.08
        static let customBorder:     Double = 0.75
        static let profileDimmed:    Double = 0.35
        static let unselectedPlayer: Double = 0.10
        static let overlayStroke:    Double = 0.10
        static let cardDivider:      Double = 0.15
        static let gameOverScrim:    Double = 0.60
        static let dealerGlow:       Double = 0.70
        static let dashBorder:       Double = 0.40
    }

    // MARK: - Layout

    enum Layout {
        // Game board geometry
        static let sideWidth:    CGFloat = 96
        static let edgeHeight:   CGFloat = 112
        static let tooltipMaxWidth: CGFloat = 240

        // Border & stroke widths
        static let tileBorderWidth:    CGFloat = 1.5
        static let profileBorderWidth: CGFloat = 2.5
        static let dealerStrokeWidth:  CGFloat = 3
        static let dealerGlowRadius:   CGFloat = 10

        // Small component dimensions
        static let colorDot:          CGFloat = 10
        static let playerLabelWidth:  CGFloat = 28
        static let tableColumnGap:    CGFloat = 24
        static let gridSpacing:       CGFloat = 22
        static let tilePadding:       CGFloat = 10
        static let addCardDash:       [CGFloat] = [5]
        static let formRowInset = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    }

    // MARK: - Animation Timing

    enum Timing {
        static let splashFade:      Double = 0.25
        static let helpAutoDismiss: Double = 3.5
        static let selectionPause:  Double = 0.9
        static let spinStep:        Double = 0.1
    }
}
