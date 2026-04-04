import WidgetKit
import SwiftUI
import SwiftData

struct ReadingEntry: TimelineEntry {
    let date: Date
    let totalReadingTime: Double
    let todayReadingTime: Double
    let currentStreak: Int
    let currentBookTitle: String?
    let currentBookCoverPath: String?
    let currentBookTime: Double
    let weekReadDays: [Bool]  // 7 booleans, Mon=0 to Sun=6
}

struct Provider: TimelineProvider {
    let container: ModelContainer

    init() {
        let schema = Schema([Book.self, ReadingSession.self, Bookmark.self])
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.jasmina.swift-ereader")!
        let storeURL = groupURL.appendingPathComponent("library.store")
        let config = ModelConfiguration(url: storeURL)
        container = try! ModelContainer(for: schema, configurations: config)
    }

    func placeholder(in context: Context) -> ReadingEntry {
        ReadingEntry(date: Date(), totalReadingTime: 3600, todayReadingTime: 1200, currentStreak: 5, currentBookTitle: "Sample Book", currentBookCoverPath: nil, currentBookTime: 1800, weekReadDays: [true, true, true, false, true, true, false])
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadingEntry) -> Void) {
        Task { @MainActor in
            completion(makeEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadingEntry>) -> Void) {
        Task { @MainActor in
            let entry = makeEntry()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    @MainActor
    private func makeEntry() -> ReadingEntry {
        let context = container.mainContext
        let books = (try? context.fetch(FetchDescriptor<Book>())) ?? []
        let sessions = (try? context.fetch(FetchDescriptor<ReadingSession>())) ?? []

        let totalTime = books.reduce(0) { $0 + $1.totalReadingTime }

        let calendar = Calendar.current
        let todayTime = sessions
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.duration }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        while true {
            let hasSession = sessions.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
            if hasSession {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        let currentBook = books
            .filter { $0.lastOpened != nil }
            .sorted { ($0.lastOpened ?? .distantPast) > ($1.lastOpened ?? .distantPast) }
            .first

        // Get cover path - check shared container first, then documents
        var coverPath: String? = nil
        if let coverImage = currentBook?.coverImage {
            let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.jasmina.swift-ereader")!
            let sharedPath = groupURL.appendingPathComponent(coverImage).path
            if FileManager.default.fileExists(atPath: sharedPath) {
                coverPath = sharedPath
            } else {
                let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let docsPath = docsDir.appendingPathComponent(coverImage).path
                if FileManager.default.fileExists(atPath: docsPath) {
                    coverPath = docsPath
                }
            }
        }

        // Compute which days of the week have reading sessions
        let today = calendar.startOfDay(for: Date())
        let todayWeekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (todayWeekday - 2 + 7) % 7
        let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today)!

        var weekReadDays = [Bool](repeating: false, count: 7)
        for i in 0..<7 {
            let day = calendar.date(byAdding: .day, value: i, to: monday)!
            if day > today { continue }
            weekReadDays[i] = sessions.contains { calendar.isDate($0.date, inSameDayAs: day) }
        }

        return ReadingEntry(
            date: Date(),
            totalReadingTime: totalTime,
            todayReadingTime: todayTime,
            currentStreak: streak,
            currentBookTitle: currentBook?.title,
            currentBookCoverPath: coverPath,
            currentBookTime: currentBook?.totalReadingTime ?? 0,
            weekReadDays: weekReadDays
        )
    }
}

// MARK: - Small Widget (Streak)

struct StreakWidgetView: View {
    let entry: ReadingEntry

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)

            if entry.currentStreak > 0 {
                Text("\(entry.currentStreak)")
                    .font(.system(size: 36, weight: .bold))
                Text(entry.currentStreak == 1 ? "day" : "days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("0")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.secondary)
                Text("Start reading!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer().frame(height: 2)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundColor(.pink)
                Text(formatTime(entry.todayReadingTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

// MARK: - Medium Widget (Current Book)

struct CurrentBookWidgetView: View {
    let entry: ReadingEntry

    var body: some View {
        HStack(spacing: 14) {
            // Book cover
            if let coverPath = entry.currentBookCoverPath,
               let uiImage = UIImage(contentsOfFile: coverPath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fill)
                    .frame(width: 70, height: 105)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 70, height: 105)
                    .overlay(
                        Image(systemName: "book.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
            }

            // Book info
            VStack(alignment: .leading, spacing: 6) {
                if let title = entry.currentBookTitle {
                    Text("Currently Reading")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineLimit(2)

                    Spacer()

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundColor(.pink)
                            Text(formatTime(entry.currentBookTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text("\(entry.currentStreak)d")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Spacer()
                    Text("No book open yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Start reading!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            Spacer()
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

// MARK: - Widget Definition

struct ReadingStatsWidget: Widget {
    let kind: String = "swift_ereader_widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            Group {
                if #available(iOS 17.0, *) {
                    WidgetView(entry: entry)
                        .containerBackground(.fill.tertiary, for: .widget)
                } else {
                    WidgetView(entry: entry)
                        .padding()
                        .background()
                }
            }
        }
        .configurationDisplayName("Reading Stats")
        .description("Track your reading streak and current book.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: ReadingEntry

    var body: some View {
        switch family {
        case .systemMedium:
            CurrentBookWidgetView(entry: entry)
        default:
            CurrentBookSmallView(entry: entry)
        }
    }
}

// MARK: - Small Current Book Widget

struct CurrentBookSmallView: View {
    let entry: ReadingEntry

    var body: some View {
        VStack(spacing: 6) {
            if let coverPath = entry.currentBookCoverPath,
               let uiImage = UIImage(contentsOfFile: coverPath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fit)
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 53, height: 80)
                    .overlay(
                        Image(systemName: "book.fill")
                            .foregroundColor(.gray)
                    )
            }

            if let title = entry.currentBookTitle {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 8))
                    .foregroundColor(.pink)
                Text(formatTime(entry.currentBookTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

// MARK: - Streak Widget

struct StreakWidget: Widget {
    let kind: String = "swift_ereader_streak_widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            Group {
                if #available(iOS 17.0, *) {
                    StreakWidgetRouter(entry: entry)
                        .containerBackground(.fill.tertiary, for: .widget)
                } else {
                    StreakWidgetRouter(entry: entry)
                        .padding()
                        .background()
                }
            }
        }
        .configurationDisplayName("Reading Streak")
        .description("Track your daily reading streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StreakWidgetRouter: View {
    @Environment(\.widgetFamily) var family
    let entry: ReadingEntry

    var body: some View {
        switch family {
        case .systemMedium:
            StreakMediumView(entry: entry)
        default:
            StreakWidgetView(entry: entry)
        }
    }
}

// MARK: - Medium Streak Widget

struct StreakMediumView: View {
    let entry: ReadingEntry

    var body: some View {
        VStack(spacing: 12) {
            // Top row - streak info
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                Text("\(entry.currentStreak)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(entry.currentStreak == 1 ? "day streak" : "day streak")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.pink)
                    Text(formatTime(entry.todayReadingTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Week circles
            HStack(spacing: 0) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(day.didRead ? Color.orange : Color.gray.opacity(0.2))
                                .frame(width: 36, height: 36)
                            if day.isToday {
                                Circle()
                                    .stroke(day.didRead ? Color.white : Color.orange, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                            }
                            if day.didRead {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                        }
                        Text(day.label)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var weekDays: [WeekDay] {
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())
        let todayIndex = (todayWeekday - 2 + 7) % 7

        let labels = ["M", "T", "W", "T", "F", "S", "S"]
        return (0..<7).map { i in
            WeekDay(
                label: labels[i],
                didRead: entry.weekReadDays[i],
                isToday: i == todayIndex
            )
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

struct WeekDay {
    let label: String
    let didRead: Bool
    let isToday: Bool
}
