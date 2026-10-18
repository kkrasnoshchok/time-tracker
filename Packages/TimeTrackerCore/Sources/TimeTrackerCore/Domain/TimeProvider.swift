import Foundation

/// Source of "now". Logic never calls `Date()` directly, so tests control time.
public protocol TimeProvider: Sendable {
    func now() -> Date
}

public struct SystemTimeProvider: TimeProvider {
    public init() {}

    public func now() -> Date { Date() }
}
