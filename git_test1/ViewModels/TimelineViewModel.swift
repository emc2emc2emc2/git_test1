import Combine
import Foundation

@MainActor
final class TimelineViewModel: ObservableObject {

    @Published var timelineText: String = "今日尚無紀錄"
    @Published var entries: [TimelineEntry] = []
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: .now)

    private var cancellables = Set<AnyCancellable>()

    func bind(to analyzer: TrackAnalyzer) {
        analyzer.$currentDayLog
            .receive(on: RunLoop.main)
            .sink { [weak self] log in self?.update(from: log) }
            .store(in: &cancellables)

        update(from: analyzer.currentDayLog)
    }

    func selectDate(_ date: Date) {
        selectedDate = Calendar.current.startOfDay(for: date)
        if let log = PersistenceManager.shared.load(date: selectedDate) {
            update(from: log)
        } else {
            timelineText = "此日無紀錄"
            entries = []
        }
    }

    private func update(from log: DayLog) {
        timelineText = TimelineGenerator.generateText(from: log)
        entries = TimelineGenerator.generateEntries(from: log)
    }
}
