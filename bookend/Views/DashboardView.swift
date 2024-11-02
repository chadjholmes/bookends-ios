//
//  ContentView.swift
//  bookend
//
//  Created by Chad Holmes on 11/1/24.
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query private var books: [Book]
    @Query private var sessions: [ReadingSession]
    
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
            .navigationTitle("Reading Insights")
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
        VStack {
            HStack(spacing: 20) {
                StatBox(title: "Books", value: "\(books.count)")
                StatBox(title: "Pages", value: "\(totalPagesRead)")
                StatBox(title: "Hours", value: "\(totalReadingTime / 60)")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ReadingStreakCard: View {
    let sessions: [ReadingSession]
    
    var currentStreak: Int {
        // Calculate current streak of consecutive days reading
        return calculateCurrentStreak()
    }
    
    var longestStreak: Int {
        // Calculate longest streak
        return calculateLongestStreak()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Reading Streak")
                .font(.headline)
            
            HStack {
                VStack {
                    Text("\(currentStreak)")
                        .font(.title)
                        .bold()
                    Text("Current")
                        .font(.caption)
                }
                
                Spacer()
                
                VStack {
                    Text("\(longestStreak)")
                        .font(.title)
                        .bold()
                    Text("Longest")
                        .font(.caption)
                }
            }
            .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
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
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        
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
            Text("Reading Time")
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
                        AxisValueLabel("\(value.as(Int.self) ?? 0)m")
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
            Text("Reading Progress")
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
                        .foregroundStyle(.blue.opacity(0.1))
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

#Preview {
    DashboardView()
        .modelContainer(for: [Book.self, ReadingSession.self], inMemory: true)
}
