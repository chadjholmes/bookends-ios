import SwiftUI

struct BookAddedToast: View {
    var message: String
    var onDismiss: () -> Void
    var onReturnToBookshelf: () -> Void

    var body: some View {
        VStack {
            Text(message)
                .font(.headline)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.horizontal)

            HStack {
                Button("Return to Bookshelf") {
                    onReturnToBookshelf()
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Add Another Book") {
                    onDismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.top, 10)
        }
        .padding()
        .transition(.slide)
        .animation(.easeInOut)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}