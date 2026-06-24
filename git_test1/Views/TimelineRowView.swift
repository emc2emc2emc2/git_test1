import SwiftUI

struct TimelineRowView: View {
    let entry: TimelineEntry

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Image(systemName: entry.segment.mode.icon)
                    .foregroundStyle(modeColor)
                    .frame(width: 28, height: 28)
                Rectangle()
                    .frame(width: 2)
                    .foregroundStyle(modeColor.opacity(0.25))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.timeRangeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(entry.locationString)
                    .font(.body.weight(.medium))

                if let transition = entry.transitionText {
                    Label(transition, systemImage: entry.segment.mode.icon)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(modeColor.opacity(0.12), in: Capsule())
                        .foregroundStyle(modeColor)
                }
            }
            .padding(.bottom, 12)
        }
        .padding(.vertical, 4)
    }

    private var modeColor: Color {
        Color(entry.segment.mode.uiColor)
    }
}
