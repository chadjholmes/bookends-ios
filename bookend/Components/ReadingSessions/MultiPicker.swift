//
//  MultiPicker.swift
//  bookend
//
//  Created by Chad Holmes on 11/10/24.
//
import SwiftUI

struct MultiPicker: View  {

    typealias Label = String
    typealias Entry = String

    let data: [ (Label, [Entry]) ]
    @Binding var selection: [Entry]

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Spacer() // Add spacer at start
                ForEach(0..<self.data.count) { column in
                    VStack {
                        Text(self.data[column].0)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Picker(self.data[column].0, selection: self.$selection[column]) {
                            ForEach(0..<self.data[column].1.count) { row in
                                Text(verbatim: self.data[column].1[row])
                                    .tag(self.data[column].1[row])
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: geometry.size.width / CGFloat(self.data.count + 1)) // Adjust width to account for spacers
                        .frame(alignment: .center)
                        .clipped()
                    }
                }
                Spacer() // Add spacer at end
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// Preview
struct MultiPicker_Previews: PreviewProvider {
    @State static var selection: [String] = ["0", "0", "0"] // Default selection for hours, minutes, seconds

    static var previews: some View {
        MultiPicker(data: [
            ("Hours", Array(0...23).map { "\($0)" }), // Hours from 0 to 23
            ("Minutes", Array(0...59).map { "\($0)" }), // Minutes from 0 to 59
            ("Seconds", Array(0...59).map { "\($0)" }) // Seconds from 0 to 59
        ], selection: $selection)
        .frame(height: 200) // Set a fixed height for the preview
    }
}
