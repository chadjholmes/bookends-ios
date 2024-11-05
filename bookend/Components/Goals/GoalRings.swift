import SwiftUI
import SwiftData

struct GoalRings: View {
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @Environment(\.colorScheme) private var colorScheme
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
    
    private let allPeriods: [ReadingGoal.GoalPeriod] = [
        .daily,
        .weekly,
        .monthly,
        .yearly
    ]
    
    var body: some View {
        let width = UIScreen.main.bounds.width // Get screen width
        let height = UIScreen.main.bounds.height // Get screen height
        
        // Calculate ring diameters based on screen width
        let ringDiameters: [ReadingGoal.GoalPeriod: CGFloat] = [
            .daily: width * 0.55,
            .weekly: width * 0.45,
            .monthly: width * 0.35,
            .yearly: width * 0.25
        ]
        
        VStack {
            // Scrollable Date Picker
            datePicker(width: width, height: height)
                .frame(maxWidth: width, alignment: .center)
            // Rings and keys
            ZStack {
                VStack {
                    HStack {
                        keyItem(for: .daily)
                        Spacer()
                        keyItem(for: .weekly, mirrored: true) // Mirrored for Weekly
                    }
                    Spacer()
                    HStack {
                        keyItem(for: .monthly)
                        Spacer()
                        keyItem(for: .yearly, mirrored: true) // Mirrored for Yearly
                    }
                }
                .padding(width * 0.02)
                
                // Always show all rings
                ForEach(allPeriods, id: \.self) { period in
                    if let goal = goals.first(where: { $0.period == period }) {
                        GoalRing(
                            goal: goal,
                            sessions: sessions,
                            color: ringColors[period] ?? .gray,
                            width: ringWidths[period] ?? 10,
                            diameter: ringDiameters[period] ?? 200,
                            selectedDate: selectedDate
                        )
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: ringWidths[period] ?? 10)
                            .frame(width: ringDiameters[period] ?? 200)
                    }
                }
                
                // Center content
                if goals.isEmpty {
                    Image(systemName: "book.closed")
                        .font(.system(size: height * 0.03)) // Relative size based on height
                        .foregroundColor(colorScheme == .dark ? .white : .secondary)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: height * 0.03)) // Relative size based on height
                            .foregroundColor(colorScheme == .dark ? .white : .secondary)
                    }
                }
            }
            .frame(height: height * 0.35) // Adjusted height to be 35% of screen height
            .padding(.vertical)
        }
        .padding(.horizontal)
    }
    
    private func datePicker(width: CGFloat, height: CGFloat) -> some View {
        let dateRange = -2...2 // Range for the date picker
        
        return HStack(spacing: width * 0.05) { // Add spacing between main elements
            // Double left chevron
            Button(action: { changeDate(by: -5) }) {
                Image(systemName: "chevron.backward.2")
                    .font(.system(size: width * 0.045))
            }
            
            // Center date group
            HStack(spacing: width * 0.02) { // Spacing between dates
                ForEach(dateRange, id: \.self) { offset in
                    if let date = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) {
                        Text(offset == 0 ? dateFormatter.string(from: date) : String(Calendar.current.component(.day, from: date)))
                            .font(.system(size: width * 0.030))
                            .frame(width: offset == 0 ? width * 0.25 : width * 0.08)
                            .padding(.vertical, height * 0.015)
                            .background(offset == 0 ? Color.purple : Color.clear)
                            .foregroundColor(offset == 0 ? Color.white : (colorScheme == .dark ? Color.white : Color.black))
                            .cornerRadius(8)
                            .onTapGesture {
                                selectedDate = date
                            }
                    }
                }
            }
            
            // Double right chevron
            Button(action: { changeDate(by: 5) }) {
                Image(systemName: "chevron.forward.2")
                    .font(.system(size: width * 0.045))
            }
        }
        .frame(maxWidth: width, alignment: .center)
    }
    
    private func changeDate(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: value, to: selectedDate) {
            selectedDate = Calendar.current.startOfDay(for: newDate)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E MMM, d"
        return formatter
    }
    
    private func keyItem(for period: ReadingGoal.GoalPeriod, mirrored: Bool = false) -> some View {
        let width = UIScreen.main.bounds.width // Get screen width
        let height = UIScreen.main.bounds.height // Get screen height

        return HStack(spacing: 8) { // Ensure to return the HStack
            if mirrored {
                Text(period.rawValue.capitalized)
                    .font(.system(size: width * 0.035)) // Relative font size
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: true, vertical: false)
                RoundedRectangle(cornerRadius: 3)
                    .fill(ringColors[period] ?? .gray)
                    .frame(width: width * 0.035, height: width * 0.035) // Relative size
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(ringColors[period] ?? .gray)
                    .frame(width: width * 0.035, height: width * 0.035) // Relative size
                Text(period.rawValue.capitalized)
                    .font(.system(size: width * 0.035)) // Relative font size
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .frame(minWidth: 80, alignment: .leading)
        .padding(.vertical, height * 0.015) // Relative vertical padding
        .padding(.horizontal, width * 0.02) // Relative horizontal padding
        .background(colorScheme == .dark ? Color.black.opacity(0.6) : Color.white.opacity(0.8))
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
            filteredSessions = sessions.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        case .weekly:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            filteredSessions = sessions.filter { $0.date >= weekStart && $0.date < weekEnd }
        case .monthly:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            filteredSessions = sessions.filter { $0.date >= monthStart && $0.date < monthEnd }
        case .yearly:
            let yearStart = calendar.date(from: calendar.dateComponents([.year], from: selectedDate))!
            let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart)!
            filteredSessions = sessions.filter { $0.date >= yearStart && $0.date < yearEnd }
        }
        
        return goal.calculateProgress(from: filteredSessions)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: width)
                .frame(width: diameter, height: diameter)
            
            if goal != nil {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
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
