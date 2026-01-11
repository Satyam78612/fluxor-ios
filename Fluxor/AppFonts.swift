//
//  AppFonts.swift
//  Fluxor
//
//  Created by Satyam Singh on 03/12/25.
//

import SwiftUI
import UIKit

private enum FontName {
    static let text = "Inter-Regular"
    static let textBold = "Inter-Bold"
    static let textMedium = "Inter-Medium"
    static let textSemiBold = "Inter-SemiBold"
}

private func customFont(_ name: String, size: CGFloat) -> Font {
    if UIFont(name: name, size: size) != nil {
        return .custom(name, size: size)
    } else {
        return .system(size: size)
    }
}

extension Font {
    static func app(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold: return customFont(FontName.textBold, size: size)
        case .semibold: return customFont(FontName.textSemiBold, size: size)
        case .medium: return customFont(FontName.textMedium, size: size)
        default: return customFont(FontName.text, size: size)
        }
    }
}

struct SmartText: View {
    let text: String
    let size: CGFloat
    let weight: Font.Weight
    let color: Color

    init(_ text: String,
         size: CGFloat = 16,
         weight: Font.Weight = .regular,
         color: Color = .primary)
    {
        self.text = text
        self.size = size
        self.weight = weight
        self.color = color
    }

    var body: some View {
        Text(generateAttributedString(from: text))
    }

    private func generateAttributedString(from input: String) -> AttributedString {
        var container = AttributedString(input)

        container.font = .app(size: size, weight: weight)
        container.foregroundColor = color

        return container
    }
}
