import SwiftUI

struct CoverImageSection: View {
    @ObservedObject var viewModel: BookEditViewModel
    @Binding var showEditionsView: Bool

    var body: some View {
        VStack {
            Text("Cover Image Section")
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else {
                Text("No Cover Image Available")
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
