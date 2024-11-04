import SwiftUI

struct ReadingSessionCard: View {
    let session: ReadingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session on \(session.date, formatter: dateFormatter)")
                .font(.headline)
            
            HStack {
                Text("Pages: \(session.startPage) - \(session.endPage)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(session.duration) min")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

// Date formatter for displaying the session date
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()
