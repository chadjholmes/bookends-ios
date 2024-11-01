import Foundation
import UIKit

public extension Book {
    enum ImageError: Error {
        case invalidData
        case saveFailed
        case loadFailed
    }
    
    // Image handling methods
    func saveCoverImage(_ image: UIImage, quality: CGFloat = 0.8) throws {
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            throw ImageError.invalidData
        }
        
        // For smaller images, store directly in the database
        if imageData.count < 1_000_000 { // 1MB threshold
            self.coverImageData = imageData
            self.coverImageURL = nil
        } else {
            // For larger images, save to filesystem
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "\(self.id)_cover.jpg"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            do {
                try imageData.write(to: fileURL)
                self.coverImageURL = fileURL
                self.coverImageData = nil
            } catch {
                throw ImageError.saveFailed
            }
        }
    }
    
    func loadCoverImage() throws -> UIImage? {
        if let imageData = self.coverImageData {
            guard let image = UIImage(data: imageData) else {
                throw ImageError.loadFailed
            }
            return image
        }
        
        if let imageURL = self.coverImageURL {
            guard let image = UIImage(contentsOfFile: imageURL.path) else {
                throw ImageError.loadFailed
            }
            return image
        }
        
        return nil
    }

    // Add this new method
    func cleanupStoredImage() {
        // Clean up file system image if it exists
        if let imageURL = self.coverImageURL {
            try? FileManager.default.removeItem(at: imageURL)
        }
        // Clear the stored data
        self.coverImageData = nil
        self.coverImageURL = nil
    }
} 