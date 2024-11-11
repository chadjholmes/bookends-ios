import ActivityKit
import WidgetKit
import SwiftUI
import Foundation

public struct ReadingSessionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        public var elapsedTime: String
        public var dailyGoalProgress: Double
    }

    // Fixed non-changing properties about your activity go here!
    public var title: String
    public var author: String
}
