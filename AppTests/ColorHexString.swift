import AppKit
import SwiftUI

extension Color {
    /// Test helper: `#RRGGBB` in sRGB, used to compare tokens with the design hexes.
    var hexString: String {
        guard let color = NSColor(self).usingColorSpace(.sRGB) else { return "#CONVERSION-FAILED" }
        let red = Int((color.redComponent * 255).rounded())
        let green = Int((color.greenComponent * 255).rounded())
        let blue = Int((color.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
