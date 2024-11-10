import Foundation
import SwiftData

@Model
public final class ReadingGoal {
    @Attribute(.unique) public var id: UUID
    public var type: GoalType
    public var target: Int
    public var period: GoalPeriod
    public var startDate: Date
    public var isActive: Bool
    
    // For tracking progress
    public var lastProgress: Date?
    public var currentStreak: Int
    public var bestStreak: Int
    
    public enum GoalType: String, Codable {
        case pages
        case minutes
        case books
    }
    
    public enum GoalPeriod: String, Codable {
        case daily
        case weekly
        case monthly
        case yearly
    }
    
    public init(
        id: UUID = UUID(),
        type: GoalType,
        target: Int,
        period: GoalPeriod,
        startDate: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.type = type
        self.target = target
        self.period = period
        self.startDate = startDate
        self.isActive = isActive
        self.currentStreak = 0
        self.bestStreak = 0
        print("ReadingGoal initialized with id: \(id)")
    }
    
    // Calculate progress for the current period
    func progressForCurrentPeriod(sessions: [ReadingSession]) -> Double {
        let calendar = Calendar.current
        let now = Date()
        
        // Filter sessions within the current period
        let periodSessions = sessions.filter { session in
            switch period {
            case .daily:
                return calendar.isDate(session.date, inSameDayAs: now)
            case .weekly:
                return calendar.isDate(session.date, equalTo: now, toGranularity: .weekOfYear)
            case .monthly:
                return calendar.isDate(session.date, equalTo: now, toGranularity: .month)
            case .yearly:
                return calendar.isDate(session.date, equalTo: now, toGranularity: .year)
            }
        }
        
        // Calculate progress based on goal type
        let progress: Int = periodSessions.reduce(0) { sum, session in
            switch type {
            case .pages:
                return sum + (session.endPage - session.startPage)
            case .minutes:
                return sum + Int(ceil(Double(session.duration) / 60.0))
            case .books:
                return sum + (session.endPage == session.book?.totalPages ? 1 : 0)
            }
        }
        
        return Double(progress) / Double(target)
    }
    
    func calculateProgress(from sessions: [ReadingSession]) -> Double {
        let now = Date()
        let calendar = Calendar.current
        
        // Filter relevant sessions based on goal period
        let relevantSessions: [ReadingSession] = sessions.filter { session in
            switch self.period {
            case .daily:
                return calendar.isDate(session.date, inSameDayAs: now)
            case .monthly:
                return calendar.isDate(session.date, equalTo: now, toGranularity: .month)
            case .yearly:
                return calendar.isDate(session.date, equalTo: now, toGranularity: .year)
            case .weekly:
                return calendar.isDate(session.date, equalTo: now, toGranularity: .weekOfYear)
            }
        }
        
        // Calculate progress based on goal type
        let progress = relevantSessions.reduce(into: 0) { result, session in
            switch self.type {
            case .pages:
                result += (session.endPage - session.startPage)
            case .minutes:
                result += Int(ceil(Double(session.duration) / 60.0))
            case .books:
                result += (session.endPage == session.book?.totalPages ? 1 : 0)
            }
        }
        
        return Double(progress) / Double(target)
    }
} 