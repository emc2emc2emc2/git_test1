import Foundation

final class PersistenceManager {
    static let shared = PersistenceManager()
    private init() { createDirectoryIfNeeded() }

    private var logsDirectory: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("logs", isDirectory: true)
    }

    private func createDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(
            at: logsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Save / Load

    func save(dayLog: DayLog) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(dayLog) else { return }
        try? data.write(to: fileURL(for: dayLog.date), options: .atomicWrite)
    }

    func load(date: Date) -> DayLog? {
        let url = fileURL(for: date)
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(DayLog.self, from: data)
    }

    func loadAll() -> [DayLog] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: logsDirectory, includingPropertiesForKeys: nil)) ?? []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return urls
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(DayLog.self, from: Data(contentsOf: $0)) }
            .sorted { $0.date < $1.date }
    }

    private func fileURL(for date: Date) -> URL {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return logsDirectory.appendingPathComponent("\(fmt.string(from: date)).json")
    }
}
