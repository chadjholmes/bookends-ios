// Toast Modifier
import SwiftUI

struct Toast: ViewModifier {
    @Binding var isPresented: Bool
    var message: String

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if isPresented {
                Text(message)
                    .padding()
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .foregroundColor(Color(UIColor.label))
                    .cornerRadius(8)
                    .padding(.bottom, 50)
                    .transition(.opacity)
                    .zIndex(999)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                isPresented = false
                            }
                        }
                    }
            }
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        self.modifier(
          Toast(isPresented: isPresented, message: message)
        )
    }
}