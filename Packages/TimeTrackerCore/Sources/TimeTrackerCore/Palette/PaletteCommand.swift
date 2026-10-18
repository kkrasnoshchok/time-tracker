import Foundation

/// What the user typed into the palette, split into its parts.
public struct PaletteCommand: Equatable, Sendable {
    public enum CategoryRef: Equatable, Sendable {
        /// Matched a known category; carries its canonical name.
        case existing(String)
        /// No known category matched; carries the word the user typed.
        case unknown(String)
    }

    public var category: CategoryRef
    public var title: String?
    public var tags: [String]
    /// How far in the past the timer should start, in seconds.
    public var startOffset: TimeInterval

    public init(category: CategoryRef, title: String? = nil, tags: [String] = [], startOffset: TimeInterval = 0) {
        self.category = category
        self.title = title
        self.tags = tags
        self.startOffset = startOffset
    }
}
