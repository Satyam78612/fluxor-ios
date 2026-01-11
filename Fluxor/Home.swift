//  Home.swift
//  Fluxor
//
//  Created by Satyam Singh on 22/11/25.
//
//

import SwiftUI

enum FavoriteFilter: String, CaseIterable, Identifiable {
    case favorites = "Favorites"
    case all = "All"
    case trending = "Trending"
    case gainers = "Gainers"
    case losers = "Losers"
    var id: String { rawValue }
}

struct Home: View {
    @ObservedObject var marketVM: MarketViewModel
    @State private var selectedFilter: FavoriteFilter = .all
    @State private var searchText: String = ""
    @State private var isShowingWithdraw = false
    @StateObject private var walletVM = WalletViewModel()
    
    private var filteredTokens: [Token] {
        if !searchText.isEmpty {
            let searchLower = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
            var results = marketVM.allTokens.filter { token in
                token.name.lowercased().contains(searchLower) ||
                token.symbol.lowercased().contains(searchLower) ||
                token.contractAddress.lowercased().contains(searchLower)
            }
            
            if let apiToken = marketVM.searchedToken {
                if !results.contains(where: { $0.id == apiToken.id }) {
                    results.insert(apiToken, at: 0)
                }
            }
            
            return results
        }
        
        switch selectedFilter {
        case .favorites:
            return marketVM.favoriteTokens
        case .all:
            return marketVM.allTokens
        case .trending:
            return marketVM.trending
        case .gainers:
            return marketVM.gainers
        case .losers:
            return marketVM.losers
        }
    }
    
   var body: some View {
       NavigationStack {
           ZStack {
               Color("AppBackground")
                   .ignoresSafeArea()
               
               ScrollView(showsIndicators: false) {
                   VStack(alignment: .leading, spacing: 8) {
                       
                       HomeTopBar(searchText: $searchText, marketVM: marketVM)
                            .padding(.bottom, 1)
                            .onChange(of: searchText) { oldValue, newValue in
                                if newValue.isEmpty {
                                    marketVM.searchedToken = nil
                                }
                            }
                       
                       BalanceCardView(isShowingWithdraw: $isShowingWithdraw, viewModel: walletVM)
                       
                       HStack(alignment: .top, spacing: 8) {
                           FearAndGreedCard(score: marketVM.fearAndGreedScore)
                           DominanceCardView(
                            btcDominance: marketVM.btcDominance,
                            ethDominance: marketVM.ethDominance
                           )
                       }
                       
                       FavoritesHeaderView(selectedFilter: $selectedFilter)
                           .padding(.top, 6)
                       
                       LazyVStack(spacing: 0) {
                            
                            ForEach(filteredTokens) { token in
                                TokenRowView(token: token)
                            }
                            
                            if filteredTokens.isEmpty && !marketVM.isLoading {
                                Text("No tokens found for \"\(selectedFilter.rawValue)\"")
                                    .font(.app(size: 16))
                                    .foregroundColor(Color("TextSecondary"))
                                    .padding(.top, 20)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .padding(.top, -4)
                        
                    }
                   .padding(.horizontal, 11)
                   .padding(.top, -2)
                   .padding(.bottom, 50)
               }
           }
           .navigationBarBackButtonHidden(true)
           .navigationDestination(isPresented: $isShowingWithdraw) {
               WithdrawView(assets: walletVM.assets)
                   .navigationBarBackButtonHidden(true)
           }
       }
       .task {
           if marketVM.allTokens.isEmpty {
               await marketVM.loadData()
            }
        }
    }
}

struct HomeTopBar: View {
    @Binding var searchText: String
    var marketVM: MarketViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            
            NavigationLink {
                Settings()
            } label: {
                Image("Fluxor")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            
            HStack {
                TextField("Search Token or Address", text: $searchText)
                    .font(.app(size: 16))
                    .foregroundColor(Color("TextPrimary"))
                    .autocorrectionDisabled()
                    .tint(Color("TextPrimary"))
                    .textInputAutocapitalization(.never)
                    
                    .task(id: searchText) {
                        try? await Task.sleep(nanoseconds: 600_000_000)
                        
                        if searchText.count > 1 {
                            await marketVM.searchTokenByAddress(address: searchText)
                        }
                    }
                    .onSubmit {
                        if searchText.count > 1 {
                            Task {
                                await marketVM.searchTokenByAddress(address: searchText)
                            }
                        }
                    }
                Spacer()
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9.2)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("CardBackground"))
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.08), radius: 4, y: 2)
            
            Button(action: {}) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(Color("TextPrimary"))
                    .frame(width: 20, height: 20)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("CardBackground"))
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.08), radius: 4, y: 2)
            }
        }
    }
}

struct BalanceCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isShowingWithdraw: Bool
    @ObservedObject var viewModel: WalletViewModel
    
    var totalBalance: Double { viewModel.assets.reduce(0) { $0 + $1.value } }
    var todayPNL: Double { viewModel.assets.reduce(0) { $0 + $1.dayChangeUSD } }
    var todayPNLPercent: Double {
        let startOfDay = totalBalance - todayPNL
        guard startOfDay > 0 else { return 0 }
        return (todayPNL / startOfDay) * 100
    }
    
    var isPositive: Bool { todayPNL >= 0 }
    var pnlColor: Color { isPositive ? Color("AppGreen") : Color("AppRed") }
    var pnlSign: String { isPositive ? "+" : "" }
    
    var body: some View {
        VStack(spacing: 7) {
            
            Text("Total Balance (USD)")
                .font(.app(size: 15, weight: .regular))
                .foregroundColor(Color("TextSecondary"))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, -3)
                .padding(.bottom, 6)
            
            Text("$\(formatSmartValue(totalBalance))")
                .font(.app(size: 30, weight: .bold))
                .foregroundColor(Color("TextPrimary"))
                
            HStack(spacing: 5) {
               Text("Today's PnL")
                    .font(.app(size: 15, weight: .medium))
                    .foregroundColor(Color("TextSecondary"))
                            
               Text("\(pnlSign)$\(formatSmartValue(todayPNL)) (\(pnlSign)\(String(format: "%.2f", todayPNLPercent))%)")
                    .font(.app(size: 15, weight: .medium))
                    .foregroundColor(pnlColor)
           }
           .padding(.bottom, 10)
            
            HStack(spacing: 10) {
                Button(action: { isShowingWithdraw = true }) {
                    HStack(spacing: 0) {
                        Image("Send")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                        
                        Text("Send")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8.2)
                    .background((Color("TextSecondary").opacity(0.08)))
                    .foregroundColor(Color("TextPrimary"))
                    .cornerRadius(30)
                }
              
                Button(action: {}) {
                    HStack(spacing: 2) {
                        Image("Receive")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                        
                        Text("Receive")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8.2)
                    .background((Color("TextSecondary").opacity(0.08)))
                    .foregroundColor(Color("TextPrimary"))
                    .cornerRadius(30)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, -3)
        }
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color("CardBackground"))
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.08), radius: 6, y: 3)
    }
}

struct FearAndGreedCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let score: Double
  
    private let segmentColors: [Color] = [
        Color(red: 255/255, green: 59/255, blue: 48/255),
        Color(red: 255/255, green: 143/255, blue: 0/255),
        Color(red: 255/255, green: 204/255, blue: 0/255),
        Color(red: 50/255, green: 215/255, blue: 75/255).opacity(0.8),
        Color(red: 40/255, green: 205/255, blue: 65/255)
    ]
    
    private var sentimentLabel: String {
        switch score {
        case 0..<25: return "Extreme Fear"
        case 25..<45: return "Fear"
        case 45..<55: return "Neutral"
        case 55..<75: return "Greed"
        default: return "Extreme Greed"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Fear & Greed")
                .font(.app(size: 16, weight: .semibold))
                .foregroundColor(Color("TextPrimary"))
            
            ZStack {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    let radius = (w / 2) - 10
                    let centerX = w / 2
                    let centerY = h - 18
                    let center = CGPoint(x: centerX, y: centerY)
                    
                    ZStack {
                        ForEach(0..<5) { i in
                            let gap: Double = 6
                            let segmentArc = (180.0 - (4.0 * gap)) / 5.0
                            
                            let startAngle = 180.0 + (Double(i) * (segmentArc + gap))
                            let endAngle = startAngle + segmentArc
                            
                            Path { path in
                                path.addArc(
                                    center: center,
                                    radius: radius,
                                    startAngle: .degrees(startAngle),
                                    endAngle: .degrees(endAngle),
                                    clockwise: false
                                )
                            }
                            .stroke(segmentColors[i], style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        }
                     
                        let clampedScore = min(max(score, 0), 100)
                        let indicatorAngle = 180.0 + (clampedScore / 100.0) * 180.0
                        let rad = indicatorAngle * .pi / 180
                        
                        let thumbX = center.x + radius * CGFloat(cos(rad))
                        let thumbY = center.y + radius * CGFloat(sin(rad))
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 18, height: 18)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .position(x: thumbX, y: thumbY)
                      
                        VStack(spacing: 0) {
                            Text("\(Int(score))")
                                .font(.app(size: 25, weight: .bold))
                                .foregroundColor(Color("TextPrimary"))
                            
                            Text(sentimentLabel)
                                .font(.app(size: 14, weight: .medium))
                                .foregroundColor(Color("TextSecondary"))
                        }
                        .position(x: centerX, y: centerY - (radius * 0.25))
                    }
                }
                .frame(height: 93)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color("CardBackground"))
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.08), radius: 6, y: 3)
    }
}

struct DominanceCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let btcDominance: Double
    let ethDominance: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack(spacing: 8) {
                Image("btc")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                Text("Dominance")
                    .font(.app(size: 16, weight: .semibold))
                    .foregroundColor(Color("TextPrimary"))
                
                Spacer()
            }
            
            Text("\(String(format: "%.2f", btcDominance))%")
                .font(.app(size: 15, weight: .bold))
                .foregroundColor(Color("TextPrimary"))
            
            Divider()
                .background(Color("DividerColor"))
            
            HStack(spacing: 8) {
                Image("eth")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                Text("Dominance")
                    .font(.app(size: 16, weight: .semibold))
                    .foregroundColor(Color("TextPrimary"))
                
                Spacer()
            }
            
            Text("\(String(format: "%.2f", ethDominance))%")
                .font(.app(size: 15, weight: .bold))
                .foregroundColor(Color("TextPrimary"))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground").opacity(0.95))
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.08), radius: 6, y: 3)
    }
}

struct FavoritesHeaderView: View {
    @Binding var selectedFilter: FavoriteFilter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 13) {
                    ForEach(FavoriteFilter.allCases) { filter in
                        Button {
                           selectedFilter = filter
                          } label: {
                            VStack(spacing: 2) {
                                Text(filter.rawValue)
                                    .font(.app(size: 17, weight: selectedFilter == filter ? .semibold : .semibold))
                                    .foregroundColor(selectedFilter == filter ? Color("TextPrimary") : Color("TextSecondary"))
                                
                                Rectangle()
                                    .fill(Color("TextPrimary"))
                                    .frame(width: 20, height: 2)
                                    .padding(.top, 5)
                                    .cornerRadius(2)
                                    .opacity(selectedFilter == filter ? 1 : 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 0)
            }
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.top, -12)
                .padding(.horizontal, 0)
            
            HStack {
                Text("Name")
                    .foregroundColor(Color("TextSecondary"))
                    .font(.app(size: 13, weight: .semibold))
                Spacer()
                
                Text("Price")
                    .foregroundColor(Color("TextSecondary"))
                    .font(.app(size: 13, weight: .medium))
                Spacer().frame(width: 37)
                
                Text("24h chg%")
                    .foregroundColor(Color("TextSecondary"))
                    .font(.app(size: 13, weight: .medium))
            }
            .padding(.top, -12)
        }
    }
}

struct TokenRowView: View {
    let token: Token
    
    var body: some View {
        HStack(spacing: 12) {
            
            HStack(spacing: 8) {
                TokenIcon(token: token, size: 34)
                
                VStack(alignment: .leading, spacing: 2.5) {
                    Text(token.name)
                        .font(.app(size: 17, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    Text(token.symbol)
                        .font(.app(size: 14, weight: .medium))
                        .foregroundColor(Color("TextSecondary"))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                SmartPriceText(
                    value: token.price ?? 0,
                    fontSize: 16,
                    weight: .semibold,
                    color: Color("TextPrimary")
                )
                .frame(alignment: .trailing)
            }
            .padding(.trailing, 8)
            
            ChangeBadgeView(value: token.changePercent ?? 0)
        }
        .padding(.vertical, 7)
    }
}

struct ChangeBadgeView: View {
    let value: Double
    
    private var text: String {
        String(format: "%+.2f%%", value)
    }
    
    private var isPositive: Bool {
        value >= 0
    }
    
    var body: some View {
        Text(text)
            .font(.app(size: 15.2, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 80, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isPositive ? Color("AppGreen") : Color("AppRed"))
            )
    }
}

#Preview {
    Home(marketVM: MarketViewModel())
}
