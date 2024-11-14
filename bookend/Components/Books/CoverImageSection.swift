import SwiftUI

struct CoverImageSection: View {
    @ObservedObject var viewModel: BookEditViewModel
    @Binding var showEditionsView: Bool

    var body: some View {
        VStack {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else {
                Image(systemName: "book.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .foregroundColor(.primary)
            }
            
            Button("Change Edition") {
                print("Change Edition button tapped") // Debugging line
                showEditionsView = true
            }
            .disabled(viewModel.selectedBook == nil)
            .foregroundColor(viewModel.selectedBook == nil ? .gray : .blue)
        }
    }
}
