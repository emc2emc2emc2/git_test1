import SwiftUI
import UIKit

struct TimelineView: View {
    @EnvironmentObject var timelineVM: TimelineViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Scrollable compact summary at top
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(timelineVM.timelineText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .background(Color(.systemGroupedBackground))

                Divider()

                if timelineVM.entries.isEmpty {
                    Spacer()
                    Text("今日尚無軌跡紀錄")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List(timelineVM.entries) { entry in
                        TimelineRowView(entry: entry)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("今日時間軸")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DatePicker("", selection: $timelineVM.selectedDate,
                               displayedComponents: .date)
                        .labelsHidden()
                        .onChange(of: timelineVM.selectedDate) { _, date in
                            timelineVM.selectDate(date)
                        }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIPasteboard.general.string = timelineVM.timelineText
                    } label: {
                        Label("複製", systemImage: "doc.on.clipboard")
                    }
                }
            }
        }
    }
}
