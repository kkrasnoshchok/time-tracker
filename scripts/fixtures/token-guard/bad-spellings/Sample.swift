import SwiftUI

let a = Text("a").foregroundStyle(Color.secondary)
let b = Text("b").foregroundColor(Color.primary)
let c = Text("c").foregroundStyle(on ? Color.tertiary : Color.textSecondary)
let d = Text("d").font(.custom("Inter", size: 14))
let e = Text("e").font(Typography.body.weight(.bold))
let f = Text("f").font(Typography.body.weight(.light))
