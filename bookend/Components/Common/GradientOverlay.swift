import SwiftUI

struct GradientOverlay: View {
    let direction: Edge
    let color: Color
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [.clear, color.opacity(0.8)]),
            startPoint: direction == .leading ? .trailing : .leading,
            endPoint: direction == .leading ? .leading : .trailing
        )
    }
} 