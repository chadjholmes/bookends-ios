//
//  ReadingSessionLiveActivity.swift
//  ReadingSession
//
//  Created by Chad Holmes on 11/10/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

public struct ReadingSessionLiveActivity: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadingSessionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(context.attributes.title)")
                            .foregroundColor(.purple)
                            .font(.headline)
                            .lineLimit(2)
                        Text("\(context.attributes.author)")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .padding()
                    Spacer()
                    ZStack {
                    // Background circle in grey
                    Circle()
                        .stroke(Color.gray, lineWidth: 5)
                        .frame(width: 25, height: 25)
                        .padding()
                    
                    // Progress circle in purple
                    Circle()
                        .trim(from: 0, to: CGFloat(context.state.dailyGoalProgress))
                        .stroke(Color.purple, lineWidth: 5)
                        .frame(width: 25, height: 25)
                        .rotationEffect(.degrees(-90))
                        .padding()
                    }
                }
                .padding(.top)
                .padding(.leading)
                .padding(.trailing)

                // Elapsed time display
                Text("\(context.state.elapsedTime)")
                    .bold()
                    .foregroundColor(.gray)
                    .font(.title)
                    .padding()
                    .padding(.bottom, 20)
            }
            .activityBackgroundTint(Color(uiColor: .systemBackground))
            .activitySystemActionForegroundColor(Color.purple)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 20) {
                        // TODO: Add pause/resume button that uses Live Activity app Intents
                        // Button(action: {
                        //     // Toggle the activity state
                        // }) {
                        //     Image(systemName: "pause.fill")
                        // }
                        // .font(.system(size: 24))
                        // .foregroundColor(.purple)
                        // .accentColor(.gray)
                        Text("\(context.state.elapsedTime)")
                            .bold()
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ZStack {
                        // Background circle in grey
                        Circle()
                            .stroke(Color.gray, lineWidth: 5) // Grey background circle
                            .frame(width: 25, height: 25) // Set the size of the circle
                        
                        // Progress circle in purple
                        Circle()
                            .trim(from: 0, to: CGFloat(context.state.dailyGoalProgress)) // Trim the circle based on progress
                            .stroke(Color.purple, lineWidth: 5) // Set the stroke color and width
                            .frame(width: 25, height: 25) // Set the size of the circle
                            .rotationEffect(.degrees(-90)) // Rotate to start from the top
                    }
                    .padding()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading) {
                        Text("\(context.attributes.title)")
                            .foregroundColor(.purple)
                            .font(.headline)
                            .lineLimit(1)
                        Text("\(context.attributes.author)")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .padding()
                }
            } compactLeading: {
                Text("\(context.attributes.title)")
                    .foregroundColor(.purple)
                    .padding(.leading)
            } compactTrailing: {
                HStack {
                    ZStack {
                        // Background capsule in grey
                        Capsule()
                            .stroke(Color.gray, lineWidth: 4) // Grey border
                            .frame(height: 20) // Set the height for the pill shape
                            .frame(width: 60) // Set a fixed width for the capsule

                        // Progress capsule in purple
                        Capsule()
                            .trim(from: 0, to: CGFloat(context.state.dailyGoalProgress)) // Trim the capsule based on progress
                            .stroke(Color.purple, lineWidth: 3) // Set the stroke color and width
                            .frame(height: 20) // Set the height for the pill shape
                            .frame(width: 60) // Set a fixed width for the capsule

                        Text("\(context.state.elapsedTime)")
                            .font(.system(size: 12))
                            .bold()
                            .padding(.horizontal, 5) // Add some horizontal padding for better spacing
                            .frame(width: 80, alignment: .center) // Center the text within the fixed width
                    }
                }
                .padding(.leading)
            } minimal: {
                ZStack {
                    Circle()
                        .stroke(Color.gray, lineWidth: 4) // Set the stroke color and width
                        .frame(width: 15, height: 15) // Set the size of the circle
                    Circle()
                        .trim(from: 0, to: CGFloat(context.state.dailyGoalProgress)) // Trim the circle based on progress
                        .stroke(Color.purple, lineWidth: 4) // Set the stroke color and width
                        .frame(width: 15, height: 15) // Set the size of the circle
                        .rotationEffect(.degrees(-90)) // Rotate to start from the top
                }
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

public extension ReadingSessionAttributes {
    static var preview: ReadingSessionAttributes {
        ReadingSessionAttributes(title: "Adventures of Silly Goose The Trilogy (including all books)", author: "Jane Doe")
    }
}

public extension ReadingSessionAttributes.ContentState {
    static var first: ReadingSessionAttributes.ContentState {
        ReadingSessionAttributes.ContentState(elapsedTime: "00:10", dailyGoalProgress: 0.5)
    }
     
    static var second: ReadingSessionAttributes.ContentState {
        ReadingSessionAttributes.ContentState(elapsedTime: "01:30", dailyGoalProgress: 0.6)
    }
}

#Preview("Notification", as: .content, using: ReadingSessionAttributes.preview) {
   ReadingSessionLiveActivity()
} contentStates: {
    ReadingSessionAttributes.ContentState.first
    ReadingSessionAttributes.ContentState.second
}

#Preview("Minimal Dynamic Island Preview", as: .dynamicIsland(.minimal), using: ReadingSessionAttributes.preview) {
    ReadingSessionLiveActivity()
} contentStates: {
    ReadingSessionAttributes.ContentState.first
    ReadingSessionAttributes.ContentState.second
}

#Preview("Compact Dynamic Island Preview", as: .dynamicIsland(.compact), using: ReadingSessionAttributes.preview) {
    ReadingSessionLiveActivity()
} contentStates: {
    ReadingSessionAttributes.ContentState.first
    ReadingSessionAttributes.ContentState.second
}

#Preview("Expanded Dynamic Island Preview", as: .dynamicIsland(.expanded), using: ReadingSessionAttributes.preview) {
    ReadingSessionLiveActivity()
} contentStates: {
    ReadingSessionAttributes.ContentState.first
    ReadingSessionAttributes.ContentState.second
}

