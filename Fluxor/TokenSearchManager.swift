//
//  TokenSearchManager.swift
//  Fluxor
//
//  Created by Satyam Singh on 29/12/25.
//

import Foundation

class TokenSearchManager {
    static let shared = TokenSearchManager()
    
    private let backendURL = "https://fluxor-backend-ouwq.onrender.com/api/search"
    
    private init() {}
    
    func searchToken(contractAddress: String) async -> Token? {
        guard var components = URLComponents(string: backendURL) else {
            print("❌ Error: Invalid Backend URL String")
            return nil
        }
        
        components.queryItems = [URLQueryItem(name: "address", value: contractAddress)]
        
        guard let url = components.url else {
            print("❌ Error: Could not create valid URL from components")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    print("❌ Server returned error: \(httpResponse.statusCode)")
                    return nil
                }
            }
            
            let backendData = try JSONDecoder().decode(BackendTokenResponse.self, from: data)
            
            let finalID = backendData.id ?? backendData.contractAddress ?? contractAddress
            
            let deployment = TokenDeployment(
                chainId: backendData.chainId ?? 0,
                chainName: "Unknown",
                liquidityUsd: 0,
                address: backendData.contractAddress ?? contractAddress,
                decimals: 18
            )
            
            print("✅ [iOS] Found Token: \(backendData.symbol ?? "Unknown")")
            
            return Token(
                id: finalID,
                name: backendData.name ?? "Unknown",
                symbol: backendData.symbol ?? "UNK",
                logo: backendData.imageName ?? "questionmark.circle",
                deployments: [deployment],
                native_identifier: nil,
                decimal: 18,
                price: backendData.price ?? 0.0,
                changePercent: backendData.changePercent ?? 0.0
            )
            
        } catch {
            print("❌ [iOS] Search Network/Decoding Error: \(error)")
            return nil
        }
    }
}

struct BackendTokenResponse: Codable {
    let id: String?
    let source: String?
    let chainId: Int?
    let contractAddress: String?
    let name: String?
    let symbol: String?
    let price: Double?
    let changePercent: Double?
    let imageName: String?
}
