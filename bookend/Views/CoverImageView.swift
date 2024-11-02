import SwiftUI

struct CoverImageView: View {
    var coverImageData: Data?
    var coverImageURL: String?
    @Binding var selectedImage: UIImage?
    
    var body: some View {
        Group {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(8)
                    .shadow(radius: 5)
            } else if let coverURLString = coverImageURL,
                      let url = URL(string: coverURLString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                    case .failure:
                        Image(systemName: "book.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if let data = coverImageData {
                Image(uiImage: UIImage(data: data) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(8)
                    .shadow(radius: 5)
            } else {
                EmptyView()
            }
        }
    }
} 