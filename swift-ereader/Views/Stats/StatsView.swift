import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var books: [Book]
    @Query(sort: \ReadingSession.date, order: .reverse) private var sessions: [ReadingSession]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // overview cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Total Reading",
                            value: formatTime(totalReadingTime),
                            icon: "clock",
                            color: .pink
                        )
                        StatCard(
                            title: "Books",
                            value: "\(books.count)",
                            icon: "book",
                            color: .blue
                        )
                        StatCard(
                            title: "Current Streak",
                            value: "\(currentStreak) days",
                            icon: "flame",
                            color: .orange
                        )
                        StatCard(
                            title: "Today",
                            value: formatTime(todayReadingTime),
                            icon: "sun.max",
                            color: .yellow
                        )
                    }
                    .padding(.horizontal)

                    // this week bar chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This Week")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(weekData, id: \.day) { entry in
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(entry.isToday ? Color.pink : Color.pink.opacity(0.4))
                                        .frame(height: max(4, CGFloat(entry.minutes / maxWeekMinutes) * 120))
                                    Text(entry.day)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 150)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // per-book stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time Per Book")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(books.filter { $0.totalReadingTime > 0 }.sorted { $0.totalReadingTime > $1.totalReadingTime }) { book in
                            HStack {
                                if let coverURL = book.coverURL, let image = UIImage(contentsOfFile: coverURL.path) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(width: 30, height: 45)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                } else {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 30, height: 45)
                                }
                                VStack(alignment: .leading) {
                                    Text(book.title)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Text(formatTime(book.totalReadingTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Reading Stats")
        }
    }

    private var totalReadingTime: Double {
        books.reduce(0) { $0 + $1.totalReadingTime }
    }

    private var todayReadingTime: Double {
        let calendar = Calendar.current
        return sessions
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.duration }
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let hasSession = sessions.contains { session in
                calendar.isDate(session.date, inSameDayAs: checkDate)
            }
            if hasSession {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    private var weekData: [WeekEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let minutes = sessions
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.duration } / 60.0
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return WeekEntry(
                day: formatter.string(from: date),
                minutes: minutes,
                isToday: daysAgo == 0
            )
        }
    }

    private var maxWeekMinutes: Double {
        max(1, weekData.map(\.minutes).max() ?? 1)
    }

    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct WeekEntry {
    let day: String
    let minutes: Double
    let isToday: Bool
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
