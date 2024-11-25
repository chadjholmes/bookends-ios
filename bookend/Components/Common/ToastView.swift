import SwiftUI

struct ToastButton {
    let title: String
    let action: () -> Void
}

struct ToastView: View {
    let message: String
    let primaryButton: ToastButton
    let secondaryButton: ToastButton
    
    var body: some View {
      ZStack {
        Image("King")
            .resizable()
            .scaledToFit()
            .frame(width: UIScreen.main.bounds.width)
            .offset(y: -50)
            .padding(.bottom, 12)
            .zIndex(1)
        VStack(spacing: 12) {
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("Accent3"))
            
            HStack(spacing: 32) {
                Button(action: secondaryButton.action) {
                    Text(secondaryButton.title)
                        .foregroundColor(Color("Accent1"))
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color("Accent1"), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.white)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                }
                
                Button(action: primaryButton.action) {
                    Text(primaryButton.title)
                        .foregroundColor(Color("Accent1"))
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color("Accent1"), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.white)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width * 0.85)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.white))
        )
        .zIndex(2)
    }
    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
  }
}

// Toast modifier to be used by any view
extension View {
    func toast(isPresenting: Binding<Bool>, content: @escaping () -> ToastView) -> some View {
        self.overlay(
            Group {
                if isPresenting.wrappedValue {
                    // Add a dark overlay behind the toast
                    ZStack {
                        // Semi-transparent black background
                        Color.black
                            .opacity(0.8)  // Adjust opacity as needed (0.0 to 1.0)
                            .ignoresSafeArea()
                            .transition(.opacity)
                        
                        // Toast content
                        content()
                            .transition(.scale)
                    }
                }
            }
            .animation(.easeInOut, value: isPresenting.wrappedValue)
        )
    }
}

// Preview provider
#Preview {
    VStack {
        Text("Background Content")
    }
    .toast(isPresenting: .constant(true)) {
        ToastView(
            message: "Thy session hath been preserved",
            primaryButton: ToastButton(
                title: "New Session",
                action: {}
            ),
            secondaryButton: ToastButton(
                title: "Done",
                action: {}
            )
        )
    }
}
