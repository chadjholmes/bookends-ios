import ActivityKit
import WidgetKit
import SwiftUI
import Foundation

public struct ReadingSessionAttributes: ActivityAttributes {
   public struct ContentState: Codable, Hashable {
        var elapsedTime: TimeInterval
        var dailyGoalProgress: Double
        var startDate: Date
        var isTimerRunning: Bool

        public init(
            elapsedTime: TimeInterval,
            dailyGoalProgress: Double,
            startDate: Date,
            isTimerRunning: Bool
        ) {
            self.elapsedTime = elapsedTime
            self.dailyGoalProgress = dailyGoalProgress
            self.startDate = startDate
            self.isTimerRunning = isTimerRunning
        }
    }

    // Fixed non-changing properties about your activity go here!
    public var title: String
    public var author: String
    public var coverImageData: Data?
    public var dailyGoalTarget: Int

    public init(title: String, author: String, coverImageData: Data? = nil, dailyGoalTarget: Int) {
        self.title = title
        self.author = author
        self.coverImageData = coverImageData
        self.dailyGoalTarget = dailyGoalTarget
    }
}
