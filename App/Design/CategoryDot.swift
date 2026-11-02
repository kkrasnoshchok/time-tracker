import SwiftUI

/// 8px circle in the quiet tone that the stored hex maps to.
///
/// A `View` is a struct whose `body` is a computed property returning `some View`
/// (React: a function component returning "some JSX"; `some` hides the concrete
/// type, like an inferred return type). A computed property is a getter that runs
/// on every access, like `get body() {}` in a TS class.
struct CategoryDot: View {
    let storedHex: String

    var body: some View {
        Circle()
            .fill(ColorToken.category(CategoryTone(storedHex: storedHex)).color)
            .frame(width: 8, height: 8)
            .accessibilityHidden(true) // the category name next to it carries the meaning
    }
}
