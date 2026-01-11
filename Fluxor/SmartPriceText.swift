//
//  SmartPriceText.swift
//  Fluxor
//
//  Created by Satyam Singh on 30/12/25.
//

import SwiftUI

struct SmartPriceText: View {
    let value: Double
    var fontSize: CGFloat = 16
    var weight: Font.Weight = .semibold
    var color: Color = Color("TextPrimary")
    
    var body: some View {
        HStack(spacing: 0) {
            if value >= 1.0 {
                Text(formatLarge(value))
                    .font(.app(size: fontSize, weight: weight))
                    .foregroundColor(color)
                    .monospacedDigit()
            } else if value == 0 {
                Text("$0")
                    .font(.app(size: fontSize, weight: weight))
                    .foregroundColor(color)
            } else {
                let (zeroCount, formattedString) = analyzeSmallNumber(value)
                
                if zeroCount >= 4 {
                    Text("$0.0")
                        .font(.app(size: fontSize, weight: weight))
                        .foregroundColor(color)
                        .monospacedDigit()
                    
                    Text("\(zeroCount)")
                        .font(.system(size: fontSize * 0.65, weight: .bold))
                        .foregroundColor(color)
                        .baselineOffset(-fontSize * 0.25)
                        .padding(.horizontal, 1)
                    
                    Text(getSigFigures(from: formattedString, zeroCount: zeroCount))
                        .font(.app(size: fontSize, weight: weight))
                        .foregroundColor(color)
                        .monospacedDigit()
                } else {
                    Text(formatSmall(value))
                        .font(.app(size: fontSize, weight: weight))
                        .foregroundColor(color)
                        .monospacedDigit()
                }
            }
        }
    }
    
    private func formatLarge(_ val: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        let numberStr = formatter.string(from: NSNumber(value: val)) ?? "\(val)"
        return "$\(numberStr)"
    }

    private func formatSmall(_ val: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.usesSignificantDigits = true
        formatter.maximumSignificantDigits = 3
        
        let numberStr = formatter.string(from: NSNumber(value: val)) ?? "\(val)"
        return "$\(numberStr)"
    }

    private func analyzeSmallNumber(_ val: Double) -> (Int, String) {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 20
        formatter.usesGroupingSeparator = false
        
        let str = formatter.string(from: NSNumber(value: val)) ?? "\(val)"
        
        let parts = str.split(separator: ".")
        guard parts.count == 2 else { return (0, str) }
        
        let fraction = parts[1]
        var count = 0
        for char in fraction {
            if char == "0" {
                count += 1
            } else {
                break
            }
        }
        return (count, str)
    }

    private func getSigFigures(from str: String, zeroCount: Int) -> String {
        let parts = str.split(separator: ".")
        if parts.count < 2 { return "" }
        let fraction = String(parts[1])
        let sig = fraction.dropFirst(zeroCount)
      
        return String(sig.prefix(3))
    }
}
