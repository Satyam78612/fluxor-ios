//
//  DominanceMetrics.swift
//  Fluxor
//
//  Created by Satyam Singh on 21/12/25.
//

import Foundation

struct DominanceMetricsResponse: Codable, Sendable {
    let data: DominanceMetricsData 
}

struct DominanceMetricsData: Codable, Sendable {
    let btc_dominance: Double
    let eth_dominance: Double
}
