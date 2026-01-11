//
//  FearAndGreed.swift
//  Fluxor
//
//  Created by Satyam Singh on 21/12/25.
//

import Foundation

struct FearAndGreedResponse: Codable, Sendable { 
    let name: String
    let data: [FearAndGreedData]
}

struct FearAndGreedData: Codable, Sendable {
    let value: String
    let value_classification: String
    let timestamp: String
}
