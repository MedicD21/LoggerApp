import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BrandBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.brandBackground, Color.brandBackgroundElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.brandPrimary.opacity(0.16), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )

            RadialGradient(
                colors: [Color.brandAccent.opacity(0.10), .clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    func brandPanel(cornerRadius: CGFloat = 24) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.brandCard, Color.brandCardSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.brandStroke, lineWidth: 1)
                }
                .shadow(color: Color.brandShadow, radius: 22, x: 0, y: 14)
        )
    }

    func brandHeroPanel(cornerRadius: CGFloat = 30, accent: Color = .brandPrimary) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.brandSurface, Color.brandCard],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.24), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.brandStroke, lineWidth: 1)
                }
                .shadow(color: Color.brandShadow, radius: 26, x: 0, y: 16)
        )
    }

    func keyboardDoneToolbar() -> some View {
        modifier(KeyboardDoneToolbarModifier())
    }
}

private struct KeyboardDoneToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
                .fontWeight(.semibold)
            }
        }
    }

    private func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}
