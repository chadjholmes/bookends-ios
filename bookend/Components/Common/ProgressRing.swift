import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    
    init(
        progress: Double,
        color: Color = Color("Accent1"),
        lineWidth: CGFloat = 15,
        size: CGFloat = 100
    ) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        // Empty ring
        ProgressRing(progress: 0)
        
        // Half full ring
        ProgressRing(
            progress: 0.5,
            color: .purple
        )
        
        // Almost complete ring
        ProgressRing(
            progress: 0.8,
            color: .green
        )
        
        // Complete ring
        ProgressRing(
            progress: 1,
            color: .purple
        )
    }
    .padding()
    .background(Color.black) // Dark background to better see the rings
} 
