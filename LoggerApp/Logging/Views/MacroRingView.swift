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
                    .stroke(tint.opacity(0.14), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(tint, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(Int(consumed.rounded()))")
                        .font(.title3.weight(.bold))
                    Text("of \(Int(target.rounded()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 104, height: 104)

            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
    }
}

