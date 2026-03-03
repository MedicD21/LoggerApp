import SwiftUI

struct BrandMarkView: View {
    var size: CGFloat = 78

    var body: some View {
        Image("BrandMark")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: Color.brandPrimary.opacity(0.22), radius: size * 0.16, x: 0, y: size * 0.08)
            .accessibilityHidden(true)
    }
}

