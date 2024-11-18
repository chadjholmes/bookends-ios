import SwiftUI

struct BookDetailsSection: View {
    @ObservedObject var viewModel: BookEditViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Title Field
            Text("Title")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accentColor(Color("Accent1"))
            TextField("Enter title", text: $viewModel.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Author Field
            Text("Author")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter author", text: $viewModel.author)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Total Pages Field
            Text("Total Pages")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter total pages", text: $viewModel.totalPages)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            
            // ISBN Field
            Text("ISBN")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter ISBN", text: $viewModel.isbn)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Publisher Field
            Text("Publisher")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter publisher", text: $viewModel.publisher)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Publish Year Field
            Text("Publish Year")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter publish year", text: $viewModel.publishYear)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            
            // Genre Field
            Text("Genre")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter genre", text: $viewModel.genre)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Notes Field
            Text("Notes")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter notes", text: $viewModel.notes)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
} 
