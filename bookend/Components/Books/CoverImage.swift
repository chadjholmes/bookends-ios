import SwiftUI

struct CoverImage: View {
    // MARK: - Properties
    let height: CGFloat
    var coverImageData: Data?
    var coverImageURL: String?
    @Binding var selectedImage: UIImage?
    
    // MARK: - Initialization
    init(
        height: CGFloat = 200,
        coverImageData: Data? = nil,
        coverImageURL: String? = nil,
        selectedImage: Binding<UIImage?> = .constant(nil)
    ) {
        self.height = height
        self.coverImageData = coverImageData
        self.coverImageURL = coverImageURL
        self._selectedImage = selectedImage
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if let image = selectedImage {
                coverImage(uiImage: image)
            } else if let coverURLString = coverImageURL,
                      let url = URL(string: coverURLString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        coverImage(image: image)
                    case .failure:
                        placeholderImage
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if let data = coverImageData,
                      let uiImage = UIImage(data: data) {
                coverImage(uiImage: uiImage)
            } else {
                placeholderImage
            }
        }
    }
    
    // MARK: - Helper Views
    private func coverImage(image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: height)
            .cornerRadius(8)
            .shadow(radius: 5)
    }
    
    private func coverImage(uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: height)
            .cornerRadius(8)
            .shadow(radius: 5)
    }
    
    private var placeholderImage: some View {
        Image(systemName: "book.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: height)
            .foregroundColor(.gray)
    }
} 