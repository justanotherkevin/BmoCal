import Cocoa

/// Single source for UI design values (spacing, radii, alpha, colors, fonts). Views use these instead of literals.
enum Theme {
    enum Space { static let xs: CGFloat = 4; static let s: CGFloat = 8; static let m: CGFloat = 12; static let l: CGFloat = 16 }
    enum Radius { static let panel: CGFloat = 12; static let event: CGFloat = 3 }
    enum Alpha { static let past: CGFloat = 0.35; static let eventFill: CGFloat = 0.25 }

    static let nowColor = NSColor.systemRed              // only for the "now" marker
    static let urgentColor = NSColor.controlAccentColor  // only for the urgency dot
    static let minFontSize: CGFloat = 10

    static func text(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
        NSFont.systemFont(ofSize: max(size, minFontSize), weight: weight)
    }
    static func number(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
        NSFont.monospacedDigitSystemFont(ofSize: max(size, minFontSize), weight: weight)
    }
    static func eventColor(_ c: NSColor?) -> NSColor { c ?? .systemBlue }
}
