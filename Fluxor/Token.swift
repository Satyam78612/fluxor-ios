//
//  Token.swift
//  Fluxor
//
//  Created by Satyam Singh on 21/12/25.
//

import Foundation
import SwiftUI
import UIKit

struct TokenDeployment: Codable, Hashable {
    let chainId: Int
    let chainName: String
    let liquidityUsd: Double?
    let address: String
    let decimals: Int
}

struct Token: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let logo: String
    let deployments: [TokenDeployment]?
    let native_identifier: String?
    let decimal: Int?
    
    var price: Double? = 0.0
    var changePercent: Double? = 0.0
    var isFavorite: Bool = false
  
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case symbol
        case logo
        case deployments
        case native_identifier
        case decimal
        case price          
        case changePercent
    }

    init(id: String, name: String, symbol: String, logo: String, deployments: [TokenDeployment]? = nil, native_identifier: String? = nil, decimal: Int? = 18, price: Double = 0.0, changePercent: Double = 0.0) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.logo = logo
        self.deployments = deployments
        self.native_identifier = native_identifier
        self.decimal = decimal
        self.price = price
        self.changePercent = changePercent
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Token, rhs: Token) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Token {
 
    var contractAddress: String {
        if let native = native_identifier,
           native != "0x0000000000000000000000000000000000000000" {
            return native
        }
        return deployments?.first?.address ?? ""
    }
    
    var displayAddress: String {
        return contractAddress
    }

    var isNative: Bool {
        return native_identifier != nil && (deployments == nil || deployments?.isEmpty == true)
    }
}

struct TokenIcon: View {
    let name: String
    let symbol: String
    let logoUrl: String
    let size: CGFloat

    init(token: Token, size: CGFloat) {
        self.name = token.name
        self.symbol = token.symbol
        self.logoUrl = token.logo
        self.size = size
    }
    
    init(name: String, symbol: String, logo: String, size: CGFloat) {
        self.name = name
        self.symbol = symbol
        self.logoUrl = logo
        self.size = size
    }
    
    var body: some View {
        if UIImage(named: name.lowercased()) != nil {
            Image(name.lowercased())
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
        else if UIImage(named: symbol.lowercased()) != nil {
            Image(symbol.lowercased())
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
        else {
            if logoUrl.hasPrefix("http") {
                AsyncImage(url: URL(string: logoUrl)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else if phase.error != nil {
                        Image(systemName: "questionmark.circle")
                            .resizable().scaledToFit().foregroundColor(.gray)
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                Image(logoUrl)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            }
        }
    }
}
