//
//  MarketViewModel.swift
//  Fluxor
//
//  Created by Satyam Singh on 21/12/25.
//
//

import SwiftUI
import Combine

@MainActor
class MarketViewModel: ObservableObject {
    @Published var allTokens: [Token] = []
    @Published var searchedToken: Token? = nil
    @Published var isLoading: Bool = false
    @Published var favoriteTokens: [Token] = []
    @Published var trending: [Token] = []
    @Published var gainers: [Token] = []
    @Published var losers: [Token] = []
    @Published var fearAndGreedScore: Double = 50
    @Published var btcDominance: Double = 0
    @Published var ethDominance: Double = 0
    
    private var favoritesSet: Set<String> = []
    private var timer: Timer?
    private let priceBackendURL = "https://fluxor-backend-ouwq.onrender.com/api/portfolio/prices"
    
    private let aiSymbols = ["TAO", "RENDER", "FET", "OCEAN", "AGIX"]
    private let defiSymbols = ["AAVE", "UNI", "ENA", "MKR", "CRV", "PENDLE", "JUP"]
    private let l1Symbols = ["BTC", "ETH", "SOL", "BNB", "ADA", "DOT", "AVAX", "SUI", "SEI", "APT"]
    private let memeSymbols = ["DOGE", "PEPE", "SHIB", "WIF", "BONK", "FLOKI", "MEME"]
    private let rwaSymbols = ["LINK", "ONDO", "RWA", "TRU", "MPL"]

    init() {
        loadFavorites()
        loadLocalTokens()
        startPriceTimer()
        Task { await loadData() }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func loadLocalTokens() {
        guard let url = Bundle.main.url(forResource: "Contract for frontend", withExtension: "json") else {
            print("❌ Critical Error: 'Contract for frontend.json' not found in Bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decodedTokens = try JSONDecoder().decode([Token].self, from: data)
            
            self.allTokens = decodedTokens
            self.updateDerivedLists()
            print("✅ Successfully loaded \(allTokens.count) tokens from local JSON.")
        
            Task { await fetchPrices() }
            
        } catch {
            print("❌ JSON Decoding Error: \(error)")
        }
    }
    
    func startPriceTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchPrices()
            }
        }
    }
    
    func fetchPrices() async {
        guard !allTokens.isEmpty else { return }
    
        let ids = allTokens.map { $0.id }.joined(separator: ",")
        
        guard var components = URLComponents(string: priceBackendURL) else { return }
        components.queryItems = [URLQueryItem(name: "ids", value: ids)]
        
        guard let url = components.url else { return }
        
        print("📡 Fetching prices for \(allTokens.count) tokens...")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("❌ Price Server Error: Status Code \(httpResponse.statusCode)")
                return
            }

            let priceData = try JSONDecoder().decode([String: TokenPriceInfo].self, from: data)
            
            if !priceData.isEmpty {
                var updatedCount = 0
            
                for index in allTokens.indices {
                    let tokenID = allTokens[index].id
                    
                    if let info = priceData[tokenID] {
                        let newPrice = info.usd ?? allTokens[index].price ?? 0
                        let newChange = info.usd_24h_change ?? allTokens[index].changePercent ?? 0
                        
                        if allTokens[index].price != newPrice || allTokens[index].changePercent != newChange {
                            allTokens[index].price = newPrice
                            allTokens[index].changePercent = newChange
                            updatedCount += 1
                        }
                    }
                }
                
                if updatedCount > 0 {
                    updateDerivedLists()
                    print("✅ Updated prices for \(updatedCount) tokens.")
                } else {
                    print("⚠️ Price data received but no values changed.")
                }
            } else {
                print("⚠️ Backend returned empty price list.")
            }
            
        } catch {
            print("❌ Price Fetch Failed: \(error)")
        }
    }
    
    func loadData() async {
        await fetchFearAndGreed()
        await fetchDominance()
    }
    
    private func updateDerivedLists() {
        self.favoriteTokens = allTokens.filter { favoritesSet.contains($0.id) }
        
        self.trending = Array(allTokens.sorted {
            abs($0.changePercent ?? 0) > abs($1.changePercent ?? 0)
        }.prefix(10))
        
        self.gainers = allTokens
            .filter { ($0.changePercent ?? 0) > 0 }
            .sorted { ($0.changePercent ?? 0) > ($1.changePercent ?? 0) }
        
        self.losers = allTokens
            .filter { ($0.changePercent ?? 0) < 0 }
            .sorted { ($0.changePercent ?? 0) < ($1.changePercent ?? 0) }
    }
    
    func fetchFearAndGreed() async {
        guard let url = URL(string: "https://api.alternative.me/fng/?limit=1") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedResponse = try JSONDecoder().decode(FearAndGreedResponse.self, from: data)
            if let latest = decodedResponse.data.first {
                self.fearAndGreedScore = Double(latest.value) ?? 50
            }
        } catch {
            print("⚠️ Fear/Greed Error: \(error.localizedDescription)")
        }
    }

    func fetchDominance() async {
        guard let url = URL(string: "https://pro-api.coinmarketcap.com/v1/global-metrics/quotes/latest") else { return }
        var request = URLRequest(url: url)
        request.addValue("4b380165876b4ec18e100af29717b1e4", forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decodedResponse = try JSONDecoder().decode(DominanceMetricsResponse.self, from: data)
            self.btcDominance = decodedResponse.data.btc_dominance
            self.ethDominance = decodedResponse.data.eth_dominance
        } catch {
            print("⚠️ Dominance Error: \(error.localizedDescription)")
        }
    }
    
    func toggleFavorite(for token: Token) {
        if favoritesSet.contains(token.id) {
            favoritesSet.remove(token.id)
            if let idx = allTokens.firstIndex(where: { $0.id == token.id }) { allTokens[idx].isFavorite = false }
        } else {
            favoritesSet.insert(token.id)
            if let idx = allTokens.firstIndex(where: { $0.id == token.id }) { allTokens[idx].isFavorite = true }
        }
        saveFavorites()
        self.favoriteTokens = allTokens.filter { favoritesSet.contains($0.id) }
        objectWillChange.send()
    }
    
    func tokens(for tab: MarketTab) -> [Token] {
        switch tab {
        case .all: return allTokens
        case .favorites: return favoriteTokens
        case .gainers: return gainers
        case .losers: return losers
        case .trending: return trending
        case .ai: return allTokens.filter { aiSymbols.contains($0.symbol.uppercased()) }
        case .defi: return allTokens.filter { defiSymbols.contains($0.symbol.uppercased()) }
        case .l1: return allTokens.filter { l1Symbols.contains($0.symbol.uppercased()) }
        case .meme: return allTokens.filter { memeSymbols.contains($0.symbol.uppercased()) }
        case .rwa: return allTokens.filter { rwaSymbols.contains($0.symbol.uppercased()) }
        default: return allTokens
        }
    }
    
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoritesSet), forKey: "favorites")
    }
    
    private func loadFavorites() {
        if let saved = UserDefaults.standard.array(forKey: "favorites") as? [String] {
            favoritesSet = Set(saved)
        }
    }

    func searchTokenByAddress(address: String) async {
            let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
            guard cleanAddress.count > 1 else { return }
            
            await MainActor.run {
                self.isLoading = true
                self.searchedToken = nil
            }
            
            if let foundToken = await TokenSearchManager.shared.searchToken(contractAddress: cleanAddress) {
                await MainActor.run {
                    self.searchedToken = foundToken
                    
                    if let index = self.allTokens.firstIndex(where: { $0.id == foundToken.id }) {
                        self.allTokens[index].price = foundToken.price
                        self.allTokens[index].changePercent = foundToken.changePercent
                    }
                    
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    print("⚠️ [ViewModel] Search failed or returned 404. Clearing result.")
                    self.searchedToken = nil
                    self.isLoading = false
                }
            }
        }
}

struct TokenPriceInfo: Codable {
    let usd: Double?
    let usd_24h_change: Double?
}
