import SwiftUI

#if DEBUG
#Preview("x") { Text("x") }
#endif
let a = base.green + rgb.gray + tone.blue
let b = Text("b").foregroundStyle(Color.textPrimary)
let c = Text("c").font(Typography.body)
let d = grayscale + greenish + redshift
let e = whiteboard + blackout + NSFontManager + fontWeightLight + customFont
let f = Text("f").fontWeight(.regular)
let g = Text("g").fontWeight(.medium)
let h = Text("h").font(.bodyText).foregroundStyle(.primaryAction)
let i = Text("i").typeRole(.body).typeRole(.caption)
let j = Text("j").fontWeight(.regular).fontWeight( .medium )
let k = bold + boldly + whiteSpace
let l = Text("l").font(Font.customFoo)
let m = Text("m").foregroundStyle(Color.secondaryAction).foregroundColor(Color.primaryText)
let n = Text("n").font(.customBody).font(Typography.custom)
let o = Text("o").font(Typography.body.weight(.regular)).font(Typography.body.weight(.medium))
