import SwiftUI

struct MacroRingView: View {
    let title: String
    let consumed: Double
    let target: Double
    let tint: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(consumed / target, 1.0)
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.brandSurface, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(tint, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(Int(consumed.rounded()))")
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.brandInk)
                    Text("of \(Int(target.rounded()))")
                        .font(.caption)
                        .foregroundStyle(Color.brandMuted)
                }
            }
            .frame(width: 104, height: 104)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandInk)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .brandPanel(cornerRadius: 26)
        .frame(maxWidth: .infinity)
    }
}
