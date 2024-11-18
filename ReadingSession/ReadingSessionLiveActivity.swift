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
            let totalProgress = getTotalProgress(
                dailyGoalTarget: context.attributes.dailyGoalTarget,
                dailyGoalProgress: context.state.dailyGoalProgress,
                isTimerRunning: context.state.isTimerRunning,
                startDate: context.state.startDate,
                elapsedTime: context.state.elapsedTime
            )
            VStack {
                // Top section with book info and progress
                HStack(alignment: .center, spacing: 0) {
                    // Leading - Book cover
                    if let coverImageData = context.attributes.coverImageData,
                       let uiImage = UIImage(data: coverImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                            .cornerRadius(8)
                            .padding(.leading)
                    }
                    
                    // Center - Title and author
                    VStack(alignment: .leading) {
                        Text("\(context.attributes.title)")
                            .foregroundColor(Color("Accent1"))
                            .font(.subheadline)  // Changed to match expanded view
                            .lineLimit(1)        // Changed to match expanded view
                        Text("\(context.attributes.author)")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Trailing - Progress indicator
                    ZStack(alignment: .center) {
                        let elapsedTime = getElapsedTime(
                            isTimerRunning: context.state.isTimerRunning,
                            startDate: context.state.startDate,
                            elapsedTime: context.state.elapsedTime
                        )
                        // Create date range from elapsed time
                        let startDate = Date(timeIntervalSinceNow: -elapsedTime)
                        let endDate = startDate.addingTimeInterval(Double(context.attributes.dailyGoalTarget))
                        let dateRange = startDate...endDate
                        
                        if context.state.isTimerRunning {
                            ProgressView(timerInterval: dateRange, countsDown: false)
                                .tint(Color("Accent1"))
                                .progressViewStyle(.circular)
                                .foregroundStyle(.clear)
                                .frame(height: 55)
                        } else {
                            ProgressView(value: elapsedTime, total: Double(context.attributes.dailyGoalTarget))
                                .tint(Color("Accent1"))
                                .progressViewStyle(.circular)
                                .foregroundStyle(.clear)
                                .frame(height: 55)
                        }
                        
                        if context.state.isTimerRunning {
                            Text(Date(timeIntervalSinceNow: -getElapsedTime(
                                isTimerRunning: context.state.isTimerRunning,
                                startDate: context.state.startDate,
                                elapsedTime: context.state.elapsedTime)), 
                                style: .timer)
                                .font(.system(size: 10))
                                .bold()
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.primary)
                                .frame(width: 50, height: 20)
                                .padding()
                        } else {
                            Text(formatElapsedTime(context.state.elapsedTime))
                                .font(.system(size: 10))
                                .bold()
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(width: 50, height: 20)
                                .padding()
                        }
                    }
                    .padding(.trailing)
                }
            }
            .activityBackgroundTint(Color(uiColor: .systemBackground))
            .activitySystemActionForegroundColor(Color("Accent1"))
        } dynamicIsland: { context in
            let totalProgress = getTotalProgress(
                dailyGoalTarget: context.attributes.dailyGoalTarget,
                dailyGoalProgress: context.state.dailyGoalProgress,
                isTimerRunning: context.state.isTimerRunning,
                startDate: context.state.startDate,
                elapsedTime: context.state.elapsedTime
            )
            
            return DynamicIsland {
                // Expanded UI goes here. Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading, priority: 10) {
                    if let coverImageData = context.attributes.coverImageData,
                       let uiImage = UIImage(data: coverImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 65)
                            .cornerRadius(10)
                            .padding(.leading, 5)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack {
                        ZStack(alignment: .topTrailing) {
                            // Background capsule in grey
                            let elapsedTime = getElapsedTime(
                                isTimerRunning: context.state.isTimerRunning,
                                startDate: context.state.startDate,
                                elapsedTime: context.state.elapsedTime
                            )
                            // Create date range from elapsed time
                            let startDate = Date(timeIntervalSinceNow: -elapsedTime)
                            let endDate = startDate.addingTimeInterval(Double(context.attributes.dailyGoalTarget))
                            let dateRange = startDate...endDate
                            
                            if context.state.isTimerRunning {
                                ProgressView(timerInterval: dateRange, countsDown: false)
                                    .tint(Color("Accent1"))
                                    .progressViewStyle(.circular)
                                    .foregroundStyle(.clear)
                                    .frame(height: 65)
                            } else {
                                ProgressView(value: elapsedTime, total: Double(context.attributes.dailyGoalTarget))
                                    .tint(Color("Accent1"))
                                    .progressViewStyle(.circular)
                                    .foregroundStyle(.clear)
                                    .frame(height: 65)
                            }
                            
                            // Timer text
                            if context.state.isTimerRunning {
                                Text(Date(timeIntervalSinceNow: -getElapsedTime(
                                    isTimerRunning: context.state.isTimerRunning,
                                    startDate: context.state.startDate,
                                    elapsedTime: context.state.elapsedTime)), 
                                    style: .timer)
                                    .font(.system(size: 12))
                                    .bold()
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .foregroundColor(.white)
                                    .frame(width: 65, height: 32.5)
                                    .padding(.top)
                            } else {
                                Text(formatElapsedTime(context.state.elapsedTime))
                                    .font(.system(size: 12))
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .frame(width: 65, height: 32.5)
                                    .padding(.top)
                            }
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("...Session actions coming soon...")
                        .padding()
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.center) {
                    HStack {
                        VStack {
                            Text("\(context.attributes.title)")
                                .foregroundColor(Color("Accent1"))
                                .font(.subheadline)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                            Text("\(context.attributes.author)")
                                .foregroundColor(.gray)
                                .font(.caption)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                if let coverImageData = context.attributes.coverImageData,
                   let uiImage = UIImage(data: coverImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                        .cornerRadius(4)
                        .padding(.leading, 10)
                        .padding(.trailing)
                }
            } compactTrailing: {
                HStack() {
                    // Background capsule in grey
                    let elapsedTime = getElapsedTime(
                        isTimerRunning: context.state.isTimerRunning,
                        startDate: context.state.startDate,
                        elapsedTime: context.state.elapsedTime
                    )
                    // Create date range from elapsed time
                    let startDate = Date(timeIntervalSinceNow: -elapsedTime)
                    let endDate = startDate.addingTimeInterval(Double(context.attributes.dailyGoalTarget))
                    let dateRange = startDate...endDate
                    if context.state.isTimerRunning {
                        Text(Date(timeIntervalSinceNow: -getElapsedTime(
                            isTimerRunning: context.state.isTimerRunning,
                            startDate: context.state.startDate,
                            elapsedTime: context.state.elapsedTime)),
                            style: .timer)
                            .font(.system(size: 12))
                            .bold()
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 20)
                    } else {
                        Text(formatElapsedTime(context.state.elapsedTime))
                            .font(.system(size: 12))
                            .bold()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(width: 50, height: 20)
                    }
                    if context.state.isTimerRunning {
                        ProgressView(timerInterval: dateRange, countsDown: false)
                            .tint(Color("Accent1"))
                            .progressViewStyle(.circular)
                            .foregroundStyle(.clear)
                            .frame(height: 25)
                            .bold()

                    } else {
                        ProgressView(value: elapsedTime, total: Double(context.attributes.dailyGoalTarget))
                            .tint(Color("Accent1"))
                            .progressViewStyle(.circular)
                            .foregroundStyle(.clear)
                            .frame(height: 25)
                            .bold()
                    }
                }
            } minimal: {
                let elapsedTime = getElapsedTime(
                    isTimerRunning: context.state.isTimerRunning,
                    startDate: context.state.startDate,
                    elapsedTime: context.state.elapsedTime
                )
                // Create date range from elapsed time
                let startDate = Date(timeIntervalSinceNow: -elapsedTime)
                let endDate = startDate.addingTimeInterval(Double(context.attributes.dailyGoalTarget))
                let dateRange = startDate...endDate
                if context.state.isTimerRunning {
                    ProgressView(timerInterval: dateRange, countsDown: false)
                        .tint(Color("Accent1"))
                        .progressViewStyle(.circular)
                        .foregroundStyle(.clear)
                        .frame(height: 25)
                        .bold()

                } else {
                    ProgressView(value: elapsedTime, total: Double(context.attributes.dailyGoalTarget))
                        .tint(Color("Accent1"))
                        .progressViewStyle(.circular)
                        .foregroundStyle(.clear)
                        .frame(height: 25)
                        .bold()
                }
            }
        }
    }

    func getTotalProgress(dailyGoalTarget: Int, dailyGoalProgress: Double, isTimerRunning: Bool, startDate: Date, elapsedTime: TimeInterval) -> Double {
        var updatedGoalProgress: Double = 0.0
        let elapsedTime = getElapsedTime(isTimerRunning: isTimerRunning, startDate: startDate, elapsedTime: elapsedTime)
        updatedGoalProgress = dailyGoalProgress + (elapsedTime / Double(dailyGoalTarget))
        return updatedGoalProgress
    }

    func getElapsedTime(isTimerRunning: Bool, startDate: Date, elapsedTime: TimeInterval) -> TimeInterval {
        // Updated to use dynamic calculation
        var updatedElapsedTime = elapsedTime   
        if updatedElapsedTime == 0 {
            updatedElapsedTime = isTimerRunning ? Date().timeIntervalSince(startDate) : elapsedTime
        } else {
            updatedElapsedTime = elapsedTime + Date().timeIntervalSince(startDate)
        }
        return updatedElapsedTime
    }

    // Custom function to format elapsed time to match SwiftUI's .timer style
    func formatElapsedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds) // h:mm:ss
        } else {
            return String(format: "%d:%02d", minutes, seconds) // m:ss
        }
    }
}

public extension ReadingSessionAttributes {
    static var preview: ReadingSessionAttributes {
        // Start with a preview image
        let previewImage = UIImage(named: "book-cover-placeholder") ?? 
                          UIImage(systemName: "book.closed.fill") ?? 
                          UIImage()
        
        // Apply the same sizing and compression logic
        let maxDimension: CGFloat = 200
        let scale = min(maxDimension / previewImage.size.width, maxDimension / previewImage.size.height)
        let newSize = CGSize(width: previewImage.size.width * scale, height: previewImage.size.height * scale)
        
        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        previewImage.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Compress with the same logic
        var imageData: Data? = nil
        var compressionQuality: CGFloat = 0.5
        while compressionQuality > 0.1 {
            if let data = resizedImage?.jpegData(compressionQuality: compressionQuality) {
                if data.count < 3000 {
                    imageData = data
                    break
                }
            }
            compressionQuality -= 0.05
        }
        
        return ReadingSessionAttributes(
            title: "The Hobbit Part 1 Part 2 Part 3 Part 4 part 5",
            author: "J.R.R. Tolkien",
            coverImageData: imageData, dailyGoalTarget: 240
        )
    }
}

public extension ReadingSessionAttributes.ContentState {
    static var first: ReadingSessionAttributes.ContentState {
        ReadingSessionAttributes.ContentState(
            elapsedTime: 0,
            dailyGoalProgress: 0,
            startDate: Date(),
            isTimerRunning: true
        )
    }
     
    static var second: ReadingSessionAttributes.ContentState {
        ReadingSessionAttributes.ContentState(
            elapsedTime: 10000,
            dailyGoalProgress: 0,
            startDate: Date(),
            isTimerRunning: false
        )
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

