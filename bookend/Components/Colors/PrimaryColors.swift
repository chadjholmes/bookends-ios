//
//  PrimaryColors.swift
//  bookend
//
//  Created by Chad Holmes on 11/15/24.
//
import SwiftUI

extension Color {
    static let dynamicPrimaryColor = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? .black : UIColor(hue: 0, saturation:0, brightness: 0, alpha: 0.10)
    })
}

