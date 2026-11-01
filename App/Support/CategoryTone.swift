import Foundation

/// One of the eight muted category tones. Stored `colorHex` values are never
/// rewritten; they are mapped to a tone at render time.
enum CategoryTone: String, CaseIterable, Sendable {
    case clay, ochre, moss, lagoon, slate, plum, rose, taupe

    /// Order used to break exact distance ties: earlier wins.
    static let tieBreakOrder: [CategoryTone] = [.clay, .ochre, .moss, .lagoon, .slate, .plum, .rose, .taupe]

    var hex: String {
        switch self {
        case .clay: "#B4705A"
        case .ochre: "#B8964A"
        case .moss: "#8A9A6A"
        case .lagoon: "#5F8A88"
        case .slate: "#6F86A0"
        case .plum: "#8D6F8F"
        case .rose: "#B88A8A"
        case .taupe: "#7A7570"
        }
    }

    /// The bright hexes Core assigns to new categories, each pinned to its own tone.
    private static let coreDefaults: [String: CategoryTone] = [
        "#0A84FF": .slate, "#30D158": .moss, "#FF9F0A": .clay, "#FF453A": .rose,
        "#BF5AF2": .plum, "#64D2FF": .lagoon, "#FFD60A": .ochre, "#AC8E68": .taupe
    ]

    init(storedHex: String) {
        let key = storedHex.uppercased()
        if let tone = Self.coreDefaults[key] {
            self = tone
        } else if let rgb = Self.rgb(fromHex: key) {
            let lab = Oklab(rgb)
            var distances: [CategoryTone: Double] = [:]
            for tone in Self.allCases {
                if let toneRGB = Self.rgb(fromHex: tone.hex) {
                    distances[tone] = lab.distance(to: Oklab(toneRGB))
                }
            }
            self = Self.nearest(toDistances: distances)
        } else {
            self = .taupe
        }
    }

    /// Smallest distance wins; an exact tie goes to the earlier tone in `tieBreakOrder`.
    static func nearest(toDistances distances: [CategoryTone: Double]) -> CategoryTone {
        var best: (tone: CategoryTone, distance: Double)?
        for tone in tieBreakOrder {
            guard let distance = distances[tone] else { continue }
            if best == nil || distance < best!.distance {
                best = (tone, distance)
            }
        }
        return best?.tone ?? .taupe
    }

    /// `#RRGGBB` only (leading `#` required, hex digits only).
    private static func rgb(fromHex hex: String) -> SRGB? {
        guard hex.hasPrefix("#") else { return nil }
        let digits = hex.dropFirst()
        guard digits.count == 6, digits.allSatisfy(\.isHexDigit),
              let value = UInt32(digits, radix: 16) else { return nil }
        return SRGB(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

private struct SRGB {
    let red: Double
    let green: Double
    let blue: Double
}

/// Oklab coordinates, so "nearest" matches perceived color difference.
private struct Oklab {
    let lightness: Double
    let greenRed: Double
    let blueYellow: Double

    init(_ rgb: SRGB) {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        let red = linear(rgb.red), green = linear(rgb.green), blue = linear(rgb.blue)
        let long = cbrt(0.4122214708 * red + 0.5363325363 * green + 0.0514459929 * blue)
        let medium = cbrt(0.2119034982 * red + 0.6806995451 * green + 0.1073969566 * blue)
        let short = cbrt(0.0883024619 * red + 0.2817188376 * green + 0.6299787005 * blue)
        lightness = 0.2104542553 * long + 0.7936177850 * medium - 0.0040720468 * short
        greenRed = 1.9779984951 * long - 2.4285922050 * medium + 0.4505937099 * short
        blueYellow = 0.0259040371 * long + 0.7827717662 * medium - 0.8086757660 * short
    }

    func distance(to other: Oklab) -> Double {
        let dLight = lightness - other.lightness
        let dGreenRed = greenRed - other.greenRed
        let dBlueYellow = blueYellow - other.blueYellow
        return (dLight * dLight + dGreenRed * dGreenRed + dBlueYellow * dBlueYellow).squareRoot()
    }
}
