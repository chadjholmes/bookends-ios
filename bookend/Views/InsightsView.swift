//
//  InsightsDaView.swift
//  bookend
//
//  Created by Chad Holmes on 11/1/24.
//

import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @Query private var sessions: [ReadingSession]
    @Query private var groups: [BookGroup]
    @Query private var relationships: [BookGroupRelationship]

    private func nukeGroupData() {
        // Delete all relationships first
        relationships.forEach { relationship in
            modelContext.delete(relationship)
        }
        
        // Delete all groups
        groups.forEach { group in
            modelContext.delete(group)
        }
        
        // Save changes
        try? modelContext.save()
    }
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Stats Card
                    QuickStatsCard(books: books, sessions: sessions)
                    
                    // Reading Streak Card
                    ReadingStreakCard(sessions: sessions)
                    
                    // Reading Time Distribution
                    ReadingTimeCard(sessions: sessions)
                    
                    // Pages Read Over Time
                    ReadingProgressCard(sessions: sessions)
                    
                    // Book Completion Rate
                    BookCompletionCard(books: books)
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct QuickStatsCard: View {
    let books: [Book]
    let sessions: [ReadingSession]
    
    var totalPagesRead: Int {
        sessions.reduce(0) { sum, session in
            sum + (session.endPage - session.startPage)
        }
    }
    
    var totalReadingTime: Int {
        sessions.reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatBox(title: "Books", value: "\(books.count)")
                StatBox(title: "Pages", value: "\(totalPagesRead)")
                StatBox(title: "Hours", value: "\(totalReadingTime / 60)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ReadingStreakCard: View {
    let sessions: [ReadingSession]
    
    var weeklyStreaks: [(date: Date, didRead: Bool)] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0...6).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let dayStart = calendar.startOfDay(for: date)
            let didRead = sessions.contains { calendar.isDate($0.date, inSameDayAs: dayStart) }
            return (date: dayStart, didRead: didRead)
        }.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading Streak")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(weeklyStreaks, id: \.date) { day in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(day.didRead ? Color.green : Color.gray.opacity(0.3))
                                .frame(height: 40)
                            
                            Text(day.date, format: .dateTime.weekday(.narrow))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack(spacing: 40) {
                    VStack(alignment: .leading) {
                        Text("\(currentStreak)")
                            .font(.title3)
                            .bold()
                        Text("Current")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("\(longestStreak)")
                            .font(.title3)
                            .bold()
                        Text("Longest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    var currentStreak: Int {
        // Calculate current streak of consecutive days reading
        return calculateCurrentStreak()
    }
    
    var longestStreak: Int {
        // Calculate longest streak
        return calculateLongestStreak()
    }
    
    private func calculateCurrentStreak() -> Int {
        let sortedSessions = sessions.sorted { $0.date > $1.date }
        var streak = 0
        var currentDate = Date()
        
        for session in sortedSessions {
            let calendar = Calendar.current
            if calendar.isDate(session.date, inSameDayAs: currentDate) {
                if streak == 0 { streak = 1 }
            } else if let daysBetween = calendar.dateComponents([.day], from: session.date, to: currentDate).day,
                      daysBetween == 1 {
                streak += 1
                currentDate = session.date
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak() -> Int {
        let sortedSessions = sessions.sorted { $0.date < $1.date }
        var longestStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        for session in sortedSessions {
            if let last = lastDate {
                let calendar = Calendar.current
                if let daysBetween = calendar.dateComponents([.day], from: last, to: session.date).day {
                    if daysBetween == 1 {
                        currentStreak += 1
                    } else if daysBetween == 0 {
                        // Same day, continue
                    } else {
                        longestStreak = max(longestStreak, currentStreak)
                        currentStreak = 1
                    }
                }
            } else {
                currentStreak = 1
            }
            lastDate = session.date
        }
        
        return max(longestStreak, currentStreak)
    }
}

struct ReadingTimeCard: View {
    let sessions: [ReadingSession]
    
    var weeklyReadingTime: [(date: Date, minutes: Int)] {
        guard !sessions.isEmpty else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        _ = calendar.date(byAdding: .day, value: -7, to: now)!
        
        // Create array of last 7 days
        var result: [(Date, Int)] = []
        for dayOffset in 0...6 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let dayStart = calendar.startOfDay(for: date)
            
            // Find sessions for this day
            let dayMinutes = sessions
                .filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
                .reduce(0) { $0 + $1.duration }
            
            result.append((date, dayMinutes))
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Minutes Per Day")
                .font(.headline)
            
            if weeklyReadingTime.isEmpty {
                Text("No reading sessions recorded yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Chart {
                    ForEach(weeklyReadingTime, id: \.date) { item in
                        LineMark(
                            x: .value("Week", item.date),
                            y: .value("Minutes", item.minutes)
                        )
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Week", item.date),
                            y: .value("Minutes", item.minutes)
                        )
                        .foregroundStyle(.green.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel("\(value.as(Int.self) ?? 0)")
                    }
                }
            }
            
            Text("Average: \(averageReadingTime) minutes per session")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    var averageReadingTime: Int {
        guard !sessions.isEmpty else { return 0 }
        return sessions.reduce(0) { $0 + $1.duration } / sessions.count
    }
}

struct ReadingProgressCard: View {
    let sessions: [ReadingSession]
    
    var dailyProgress: [(date: Date, pages: Int)] {
        guard !sessions.isEmpty else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Create array of last 7 days
        var result: [(Date, Int)] = []
        for dayOffset in 0...6 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let dayStart = calendar.startOfDay(for: date)
            
            // Find sessions for this day
            let dayPages = sessions
                .filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
                .reduce(0) { sum, session in
                    sum + (session.endPage - session.startPage)
                }
            
            result.append((dayStart, dayPages))
        }
        
        return result.reversed()
    }
    
    // Calculate trend line points
    var trendLinePoints: [(date: Date, pages: Double)] {
        guard dailyProgress.count > 1 else { return [] }
        
        let xValues = Array(0..<dailyProgress.count).map(Double.init)
        let yValues = dailyProgress.map { Double($0.pages) }
        
        // Calculate linear regression
        let slope = calculateSlope(xValues: xValues, yValues: yValues)
        let intercept = calculateIntercept(xValues: xValues, yValues: yValues, slope: slope)
        
        // Create trend line points
        return dailyProgress.enumerated().map { index, item in
            let x = Double(index)
            let y = slope * x + intercept
            return (date: item.date, pages: y)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pages Per Day")
                .font(.headline)
            
            if dailyProgress.isEmpty {
                Text("No reading sessions recorded yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Chart {
                    ForEach(dailyProgress, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Pages", item.pages)
                        )
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Pages", item.pages)
                        )
                        .foregroundStyle(.purple.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // Calculate linear regression slope
    private func calculateSlope(xValues: [Double], yValues: [Double]) -> Double {
        let n = Double(xValues.count)
        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map { $0 * $1 }.reduce(0, +)
        let sumXX = xValues.map { $0 * $0 }.reduce(0, +)
        
        let denominator = n * sumXX - sumX * sumX
        guard denominator != 0 else { return 0 }
        return (n * sumXY - sumX * sumY) / denominator
    }
    
    // Calculate linear regression intercept
    private func calculateIntercept(xValues: [Double], yValues: [Double], slope: Double) -> Double {
        let meanX = xValues.reduce(0, +) / Double(xValues.count)
        let meanY = yValues.reduce(0, +) / Double(yValues.count)
        
        return meanY - slope * meanX
    }
}

struct BookCompletionCard: View {
    let books: [Book]
    
    var completionRate: Double {
        guard !books.isEmpty else { return 0 }
        let completed = books.filter { $0.currentPage == $0.totalPages }.count
        return Double(completed) / Double(books.count) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Completion Rate")
                .font(.headline)
            
            Text("\(Int(completionRate))% of books completed")
                .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview("Insights") {
    InsightsView_Preview.preview
}

// Separate struct to handle the preview setup
private struct InsightsView_Preview {
    @MainActor
    static var preview: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Book.self,
            ReadingSession.self,
            BookGroup.self,
            BookGroupRelationship.self,
            ReadingGoal.self,
            configurations: config
        )
        
        // Create sample books
        let books = [
            Book(
                title: "Dune",
                author: "Frank Herbert",
                genre: "Science Fiction",
                totalPages: 412,
                isbn: "9780441172719",
                publisher: "Ace Books",
                publishYear: 1965,
                currentPage: 412,
                externalReference: ["olid": "OL1532198W"]
            ),
            Book(
                title: "Project Hail Mary",
                author: "Andy Weir",
                genre: "Science Fiction",
                totalPages: 496,
                isbn: "9780593135204",
                publisher: "Ballantine Books",
                publishYear: 2021,
                currentPage: 280,
                externalReference: ["olid": "OL27912876W"]
            ),
            Book(
                title: "Foundation",
                author: "Isaac Asimov",
                genre: "Science Fiction",
                totalPages: 255,
                isbn: "9780553293357",
                publisher: "Bantam Spectra",
                publishYear: 1951,
                currentPage: 255,
                externalReference: ["olid": "OL46125W"]
            ),
            Book(
                title: "Snow Crash",
                author: "Neal Stephenson",
                genre: "Science Fiction",
                totalPages: 468,
                isbn: "9780553380958",
                publisher: "Bantam Books",
                publishYear: 1992,
                currentPage: 123,
                externalReference: ["olid": "OL1794949W"]
            )
        ]
        
        // Add books to container
        for book in books {
            container.mainContext.insert(book)
        }
        
        // Create reading sessions over the past week
        let calendar = Calendar.current
        let now = Date()
        
        let sessions: [ReadingSession] = [
            // Today: Long reading session of Dune
            ReadingSession(
                book: books[0],
                startPage: 380,
                endPage: 412,
                duration: 45*60,
                date: now
            ),
            
            // Yesterday: Project Hail Mary
            ReadingSession(
                book: books[1],
                startPage: 250,
                endPage: 280,
                duration: 60*60,
                date: calendar.date(byAdding: .day, value: -1, to: now)!
            ),
            
            // 3 days ago: More Project Hail Mary
            ReadingSession(
                book: books[1],
                startPage: 200,
                endPage: 250,
                duration: 90*60,
                date: calendar.date(byAdding: .day, value: -3, to: now)!
            ),
            
            // 4 days ago: Finished Foundation
            ReadingSession(
                book: books[2],
                startPage: 200,
                endPage: 255,
                duration: 120*60,
                date: calendar.date(byAdding: .day, value: -4, to: now)!
            ),
            
            // 5 days ago: Started Snow Crash
            ReadingSession(
                book: books[3],
                startPage: 100,
                endPage: 123,
                duration: 30*60,
                date: calendar.date(byAdding: .day, value: -5, to: now)!
            ),
            
            // A week ago: Foundation progress
            ReadingSession(
                book: books[2],
                startPage: 150,
                endPage: 200,
                duration: 75*60,
                date: calendar.date(byAdding: .day, value: -7, to: now)!
            )
        ]
        
        // Add reading sessions to container
        for session in sessions {
            container.mainContext.insert(session)
        }
        
        // Create some reading goals
        let goals = [
            ReadingGoal(
                type: .pages,
                target: 50,
                period: .daily,
                startDate: calendar.date(byAdding: .day, value: -30, to: now)!
            ),
            ReadingGoal(
                type: .minutes,
                target: 300,
                period: .weekly,
                startDate: calendar.date(byAdding: .day, value: -30, to: now)!
            ),
            ReadingGoal(
                type: .books,
                target: 4,
                period: .monthly,
                startDate: calendar.date(byAdding: .day, value: -30, to: now)!
            )
        ]
        
        // Add goals to container
        for goal in goals {
            container.mainContext.insert(goal)
        }
        
        // Create a book group
        let sciFiGroup = BookGroup(
            name: "Science Fiction Classics",
            groupDescription: "Classic sci-fi novels that defined the genre"
        )
        container.mainContext.insert(sciFiGroup)
        
        // Create group relationships
        for book in books {
            let relationship = BookGroupRelationship(book: book, group: sciFiGroup)
            container.mainContext.insert(relationship)
        }
        
        return InsightsView()
            .modelContainer(container)
    }
}
