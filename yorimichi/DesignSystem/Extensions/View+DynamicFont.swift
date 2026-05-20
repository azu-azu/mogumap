import SwiftUI

extension View {
    func dynamicFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .rounded
    ) -> some View {
        font(.system(size: size, weight: weight, design: design))
    }
}
