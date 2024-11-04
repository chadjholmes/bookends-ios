import SwiftUI
import SwiftData

struct GoalRings: View {
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date()) // State for selected date
    @State private var currentWeekOffset: Int = 0 // To track the current week offset
    @Environment(\.colorScheme) private var colorScheme // Add this line
    let goals: [ReadingGoal]
    let sessions: [ReadingSession]
    
    private let ringColors: [ReadingGoal.GoalPeriod: Color] = [
        .daily: .red,
        .weekly: .orange,
        .monthly: .blue,
        .yearly: .purple
    ]
    
    private let ringWidths: [ReadingGoal.GoalPeriod: CGFloat] = [
        .daily: 6,
        .weekly: 6,
        .monthly: 6,
        .yearly: 6
    ]
    
    private let ringDiameters: [ReadingGoal.GoalPeriod: CGFloat] = [
        .daily: 260,
        .weekly: 220,
        .monthly: 180,
        .yearly: 140
    ]
    
    private let allPeriods: [ReadingGoal.GoalPeriod] = [
        .daily,
        .weekly,
        .monthly,
        .yearly
    ]
    
    var sortedGoals: [ReadingGoal] {
        goals.sorted { $0.period.rawValue < $1.period.rawValue }
    }
    
    var body: some View {
        VStack {
            // Horizontal Date Picker
            HStack {
                // Double chevron - back 5 days
                Button(action: {
                    if let newDate = Calendar.current.date(byAdding: .day, value: -5, to: selectedDate) {
                        selectedDate = Calendar.current.startOfDay(for: newDate)
                    }
                }) {
                    Image(systemName: "chevron.backward.2")
                        .fontWeight(.bold)
                        .padding(8)
                }
                
                // Single chevron - back 1 day
                Button(action: {
                    if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                        selectedDate = Calendar.current.startOfDay(for: newDate)
                    }
                }) {
                    Image(systemName: "chevron.backward")
                        .fontWeight(.bold)
                        .padding(8)
                }
                
                Spacer()
                
                // Date display
                HStack(spacing: 0) {
                    ForEach(-2...2, id: \.self) { offset in
                        if let date = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) {
                            Text(offset == 0 ? dateFormatter.string(from: date) : String(Calendar.current.component(.day, from: date)))
                                .frame(minWidth: offset == 0 ? 80 : 34, maxWidth: offset == 0 ? 80 : 34)  // Use minWidth and maxWidth
                                .padding(.vertical, 6)
                                .background(offset == 0 ? Color.purple : Color.clear)
                                .foregroundColor(
                                    offset == 0 
                                        ? Color.white 
                                        : (colorScheme == .dark ? Color.white : Color.black)
                                )
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                // Single chevron - forward 1 day
                Button(action: {
                    if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                        selectedDate = Calendar.current.startOfDay(for: newDate)
                    }
                }) {
                    Image(systemName: "chevron.forward")
                        .fontWeight(.bold)
                        .padding(8)
                }
                
                // Double chevron - forward 5 days
                Button(action: {
                    if let newDate = Calendar.current.date(byAdding: .day, value: 5, to: selectedDate) {
                        selectedDate = Calendar.current.startOfDay(for: newDate)
                    }
                }) {
                    Image(systemName: "chevron.forward.2")
                        .fontWeight(.bold)
                        .padding(8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            ZStack {
                // Ring keys in corners
                VStack {
                    HStack {
                        // Top left - Daily
                        keyItem(for: .daily)
                        Spacer()
                        // Top right - Weekly
                        keyItem(for: .weekly)
                    }
                    Spacer()
                    HStack {
                        // Bottom left - Monthly
                        keyItem(for: .monthly)
                        Spacer()
                        // Bottom right - Yearly
                        keyItem(for: .yearly)
                    }
                }
                .padding(20)
                
                // Always show all rings, regardless of goals existence
                ForEach(allPeriods, id: \.self) { period in
                    if let goal = goals.first(where: { $0.period == period }) {
                        // Show active goal ring
                        GoalRing(
                            goal: goal,
                            sessions: sessions,
                            color: ringColors[period] ?? .gray,
                            width: ringWidths[period] ?? 10,
                            diameter: ringDiameters[period] ?? 200,
                            selectedDate: selectedDate
                        )
                    } else {
                        // Show empty ring for missing goal period
                        Circle()
                            .stroke(
                                Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2),
                                lineWidth: ringWidths[period] ?? 10
                            )
                            .frame(width: ringDiameters[period] ?? 200)
                    }
                }
                
                // Center content
                if goals.isEmpty {
                    Image(systemName: "book.closed")
                        .font(.system(size: 30))
                        .foregroundColor(colorScheme == .dark ? .white : .secondary)
                } else {
                    // Show book icon with the yearly target if it exists
                    VStack(spacing: 4) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 30))
                            .foregroundColor(colorScheme == .dark ? .white : .secondary)
                    }
                }
            }
            .frame(height: 350) // Increased height to fit all rings
            .padding(.vertical)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d" // Example: "Sun, 3"
        return formatter
    }
    
    private func unitForGoalType(_ type: ReadingGoal.GoalType) -> String {
        switch type {
        case .pages:
            return "pages"
        case .minutes:
            return "min"
        case .books:
            return "books"
        }
    }
    
    private func keyItem(for period: ReadingGoal.GoalPeriod) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(ringColors[period] ?? .gray)
                .frame(width: 14, height: 14)
                .alignmentGuide(.leading) { d in d[.leading] }
            
            Text(period.rawValue.capitalized)
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(minWidth: 80, alignment: .leading)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            colorScheme == .dark 
                ? Color.black.opacity(0.6) 
                : Color.white.opacity(0.8)
        )
        .cornerRadius(8)
    }
}

struct GoalRing: View {
    let goal: ReadingGoal?
    let sessions: [ReadingSession]
    let color: Color
    let width: CGFloat
    let diameter: CGFloat
    let selectedDate: Date
    
    var progress: Double {
        guard let goal = goal else { return 0 }
        
        let calendar = Calendar.current
        let filteredSessions: [ReadingSession]
        
        switch goal.period {
        case .daily:
            // For daily goals, only use sessions from the selected date
            filteredSessions = sessions.filter { session in
                calendar.isDate(session.date, inSameDayAs: selectedDate)
            }
            
        case .weekly:
            // For weekly goals, use sessions from the current week
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            filteredSessions = sessions.filter { session in
                session.date >= weekStart && session.date < weekEnd
            }
            
        case .monthly:
            // For monthly goals, use sessions from the current month
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            filteredSessions = sessions.filter { session in
                session.date >= monthStart && session.date < monthEnd
            }
            
        case .yearly:
            // For yearly goals, use sessions from the current year
            let yearStart = calendar.date(from: calendar.dateComponents([.year], from: selectedDate))!
            let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart)!
            filteredSessions = sessions.filter { session in
                session.date >= yearStart && session.date < yearEnd
            }
        }
        
        return goal.calculateProgress(from: filteredSessions)
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: width)
                .frame(width: diameter, height: diameter)
            
            // Progress ring (only if goal exists)
            if goal != nil {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: width,
                            lineCap: .round
                        )
                    )
                    .frame(width: diameter, height: diameter)
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ReadingGoal.self, ReadingSession.self, configurations: config)
    
    let sampleGoals = [
        ReadingGoal(type: .pages, target: 30, period: .daily, isActive: true),
        ReadingGoal(type: .pages, target: 300, period: .weekly, isActive: true),
        ReadingGoal(type: .pages, target: 5000, period: .monthly, isActive: true),
        ReadingGoal(type: .pages, target: 10000, period: .yearly, isActive: true)
    ]
    
    return Group {
        // Light mode preview
        VStack {
            GoalRings(goals: [], sessions: [])
                .padding()
            GoalRings(goals: sampleGoals, sessions: [])
                .padding()
        }
        .modelContainer(container)
        
        // Dark mode preview
        VStack {
            GoalRings(goals: [], sessions: [])
                .padding()
            GoalRings(goals: sampleGoals, sessions: [])
                .padding()
        }
        .modelContainer(container)
        .preferredColorScheme(.dark)
    }
} 