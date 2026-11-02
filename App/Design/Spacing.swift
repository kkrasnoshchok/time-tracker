import CoreGraphics

/// Spacing scale on the 4px grid. Like a `const space = {...}` object in TS:
/// no magic numbers in views.
enum Space {
    static let x1: CGFloat = 4
    static let x2: CGFloat = 8
    static let x3: CGFloat = 12
    static let x4: CGFloat = 16
    static let x5: CGFloat = 20
    static let x6: CGFloat = 24
    static let x8: CGFloat = 32
    static let x10: CGFloat = 40
    static let rowHeight: CGFloat = 44
    static let paletteFieldHeight: CGFloat = 60
}

/// Corner radii. `pill` is large enough to round any control fully.
enum Radius {
    static let input: CGFloat = 8
    static let card: CGFloat = 16
    static let panel: CGFloat = 20
    static let pill: CGFloat = 9999
}
