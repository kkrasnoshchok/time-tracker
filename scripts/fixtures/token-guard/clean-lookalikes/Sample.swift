import SwiftUI

#if DEBUG
#Preview("x") { Text("x") }
#endif
let a = base.green + rgb.gray + tone.blue
let b = Text("b").foregroundStyle(Color.textPrimary)
let c = Text("c").font(Font.custom("Inter", size: size))
let d = grayscale + greenish + redshift
