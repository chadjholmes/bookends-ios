import SwiftUI

struct ReadingSessionCard: View {
    let session: ReadingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(session.date, formatter: dateFormatter)")
                .font(.headline)
            
            HStack {
                Text("\(session.startPage) - \(session.endPage)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatDuration(session.duration))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.clear))
        .cornerRadius(8)
    }
    
    // Function to format duration from seconds to "HH:mm:ss" or "mm:ss"
    private func formatDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds) // HH:mm:ss
        } else {
            return String(format: "%02d:%02d", minutes, seconds) // mm:ss
        }
    }
}

// Date formatter for displaying the session date
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()
