import SwiftUI

// Property access and labels must not be reported.
func channel(_ rgb: RGB, size: Double) -> Double {
    let value = rgb.red + rgb.blue
    return layout(size: size) + value
}
