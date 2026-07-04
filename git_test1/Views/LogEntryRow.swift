import SwiftUI

struct LogEntryRow: View {
    let entry: GPSLogEntry

    var body: some View {
        HStack(spacing: 8) {
            Text(entry.timeString)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)

            Image(systemName: entry.mode.icon)
                .font(.caption)
                .foregroundStyle(Color(entry.mode.uiColor))
                .frame(width: 16)

            Text(entry.coordString)
                .font(.system(.caption, design: .monospaced))

            Spacer()

            Text(entry.speedString)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
