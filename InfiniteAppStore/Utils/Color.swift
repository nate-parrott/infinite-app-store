import SwiftUI

extension Color {
   init(hex: Int) {
       let r = (hex >> 16) & 0xFF
       let g = (hex >> 8) & 0xFF
       let b = hex & 0xFF
       self.init(
           red: Double(r) / 0xFF,
              green: Double(g) / 0xFF,
                blue: Double(b) / 0xFF
         )
   }
}
