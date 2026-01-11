//
//  Market.swift
//  Fluxor
//
//  Created by Satyam Singh on 22/11/25.
//

import SwiftUI

struct Market: View {
    @ObservedObject var viewModel: MarketViewModel
    
    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            MarketsPageView(viewModel: viewModel)
        }
        .task {
            if viewModel.allTokens.isEmpty {
                await viewModel.loadData()
            }
        }
    }
}

enum MarketTab: String, CaseIterable, Identifiable {
    case favorites = "Favorites"
    case all = "All"
    case trending = "Trending"
    case stocks = "Stocks"
    case gainers = "Gainers"
    case losers = "Losers"
    case rwa = "RWA"
    case ai = "AI"
    case defi = "DeFi"
    case l1 = "L1"
    case l2 = "L2"
    case cex = "CEX Token"
    case meme = "Meme"
    case depin = "DePIN"
    case oracle = "Oracle"

    var id: String { rawValue }
}

struct MarketRowView: View {
    let token: Token
    var marketVM: MarketViewModel
    @State private var showFavoriteBubble = false
    @Binding var activeTokenID: String?
    private var isPositive: Bool { (token.changePercent ?? 0) >= 0 } 
    private var signText: String { isPositive ? "+" : "-" }
    private var percentText: String { String(format: "%@%.2f%%", signText, abs(token.changePercent ?? 0)) }
    private var badgeColor: Color { isPositive ? Color("AppGreen") : Color("AppRed") }
    private var isBubbleVisible: Bool { activeTokenID == token.id }
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 8) {
                
                HStack(spacing: 6) {
                    TokenIcon(token: token, size: 34)
                        .padding(.horizontal, 2)
                    
                    VStack(alignment: .leading, spacing: 2.5) {
                        Text(token.name)
                            .font(.app(size: 17, weight: .semibold))
                        
                        Text(token.symbol.uppercased())
                            .font(.app(size: 14, weight: .medium))
                            .foregroundColor(Color("TextSecondary"))
                    }
                }
                
                Spacer()
                
                SmartPriceText(
                    value: token.price ?? 0,
                    fontSize: 16,
                    weight: .semibold,
                    color: Color("TextPrimary")
                )
                .padding(.trailing, 10)
                
                Text(percentText)
                    .font(.app(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(width: 80, height: 20)
                    .padding(.vertical, 6)
                    .background(badgeColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
             .padding(.vertical, 8)
             .padding(.trailing, 2)
             .contentShape(Rectangle())
             .onTapGesture {
                 withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                     activeTokenID = (activeTokenID == token.id) ? nil : token.id
                 }
             }
            
            if isBubbleVisible {
                FavoriteBubble(token: token, marketVM: marketVM, isShowing: Binding(
                    get: { isBubbleVisible },
                    set: { if !$0 { activeTokenID = nil } }
                ))
                .offset(y: -50)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                .zIndex(1)
            }
        }
    }
}

struct FavoriteBubble: View {
    let token: Token
    @ObservedObject var marketVM: MarketViewModel
    @Binding var isShowing: Bool

    var body: some View {
        HStack {
            Button {
                marketVM.toggleFavorite(for: token)
                withAnimation { isShowing = false }
            } label: {
                Image(systemName: token.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(token.isFavorite ? .yellow : .white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ZStack {
                Capsule()
                    .fill(Color("TextSecondary"))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                Image(systemName: "triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color("TextSecondary"))
                    .rotationEffect(.degrees(180))
                    .offset(y: 20)
            }
        )
    }
}

enum SortField {
    case none, price, change
}
enum SortDirection {
    case asc, desc
}

struct SortButton: View {
    let isActive: Bool
    let direction: SortDirection
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 5))
                    .foregroundColor(triangleColor(isUp: true))

                Image(systemName: "triangle.fill")
                    .font(.system(size: 5))
                    .rotationEffect(.degrees(180))
                    .foregroundColor(triangleColor(isUp: false))
            }
            .frame(width: 15, height: 15)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func triangleColor(isUp: Bool) -> Color {
        guard isActive else { return Color.gray.opacity(0.5) }

        if direction == .asc {
            
            return isUp ? Color.primary : Color.gray.opacity(0.5)
        } else {
           
            return isUp ? Color.gray.opacity(0.5) : Color.primary
        }
    }
}

struct MarketsPageView: View {
    @ObservedObject var viewModel: MarketViewModel
    @State private var selectedTab: MarketTab = .all
    @State private var sortField: SortField = .none
    @State private var sortDirection: SortDirection = .desc
    @State private var searchText: String = ""
    @State private var activeTokenID: String? = nil

    private var tokens: [Token] { viewModel.allTokens }

    private var filteredTokens: [Token] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        var list: [Token]
        
        if !needle.isEmpty {
            list = viewModel.allTokens.filter {
                $0.name.lowercased().contains(needle) ||
                $0.symbol.lowercased().contains(needle) ||
                $0.contractAddress.lowercased().contains(needle)
            }
            
            if let apiToken = viewModel.searchedToken {
                if !list.contains(where: { $0.id == apiToken.id }) {
                    list.insert(apiToken, at: 0)
                }
            }
        } else {
            list = viewModel.tokens(for: selectedTab)
        }
        
        var sortedList = list
        
        switch sortField {
        case .price:
            sortedList.sort { a, b in
                let priceA = a.price ?? 0
                let priceB = b.price ?? 0
                return sortDirection == .asc ? (priceA < priceB) : (priceA > priceB)
            }
        case .change:
            sortedList.sort { a, b in
                let changeA = a.changePercent ?? 0
                let changeB = b.changePercent ?? 0
                return sortDirection == .asc ? (changeA < changeB) : (changeA > changeB)
            }
        case .none:
            break
        }
        return sortedList
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            AdaptiveSearchBar(searchText: $searchText, marketVM: viewModel)
                .padding(.bottom, -1)
                .padding(.top, 7)
                .onSubmit {
                    if searchText.count > 20 {
                        Task {
                            await viewModel.searchTokenByAddress(address: searchText)
                        }
                    }
                }
                .onChange(of: searchText) { oldValue, newValue in
                    if newValue.isEmpty {
                        viewModel.searchedToken = nil
                    }
                }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(MarketTab.allCases) { tab in
                        Button {
                            selectedTab = tab
                            activeTokenID = nil
                        } label: {
                            VStack(spacing: 2) {
                                Text(tab.rawValue)
                                    .font(.app(size: 17, weight: tab == selectedTab ? .semibold : .semibold))
                                    .foregroundColor(tab == selectedTab ? Color("TextPrimary") : Color("TextSecondary"))
                                
                                Rectangle()
                                    .fill(Color("TextPrimary"))
                                    .frame(width: 15, height: 2)
                                    .padding(.top, 5)
                                    .cornerRadius(2)
                                    .opacity(tab == selectedTab ? 1 : 0)
                              }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.top, -16)
                .padding(.horizontal, 0)

            HStack(spacing: 7) {
                Text("Name")
                    .font(.app(size: 13, weight: .semibold))
                    .foregroundColor(Color("TextSecondary"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 0.6)

                HStack(spacing: 1) {
                    Text("Price")
                        .font(.app(size: 13))
                        .foregroundColor(Color("TextSecondary"))
                        .frame(width: 100, alignment: .trailing)

                    SortButton(isActive: sortField == .price, direction: sortDirection) {
                        handleSortTap(field: .price)
                    }
                }
                .frame(width: 140, alignment: .trailing)

                HStack(spacing: 1) {
                    Text("24h %")
                        .font(.app(size: 13))
                        .foregroundColor(Color("TextSecondary"))
                        .frame(width: 92, alignment: .trailing)

                    SortButton(isActive: sortField == .change, direction: sortDirection) {
                        handleSortTap(field: .change)
                    }
                }
                .frame(width: 88, alignment: .trailing)
            }
            .padding(.top, -16)
            .padding(.bottom, -25)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if filteredTokens.isEmpty {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.top, 20)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("No tokens found")
                                .font(.app(size: 16))
                                .foregroundColor(Color("TextSecondary"))
                                .padding(.top, 20)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    } else {
                        ForEach(filteredTokens) { token in
                            MarketRowView(
                               token: token,
                               marketVM: viewModel,
                               activeTokenID: $activeTokenID
                            )
                        }
                    }
                }
                .padding(.top, -6)
            }
            .onTapGesture { activeTokenID = nil }
        }
        .padding(.horizontal, 11)
        .padding(.bottom, 50)
        .background(Color("AppBackground"))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func handleSortTap(field: SortField) {
        if sortField == field {
            sortDirection = (sortDirection == .desc) ? .asc : .desc
        } else {
            sortField = field
            sortDirection = .desc
        }
    }
}

struct AdaptiveSearchBar: View {
    @Binding var searchText: String
    @ObservedObject var marketVM: MarketViewModel
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focused: Bool

    private var backgroundFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }
    private var iconColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.45)
    }
    private var placeholderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.45) : Color.black.opacity(0.38)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.app(size: 16))
                .foregroundColor(iconColor)

            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    Text("Search assets")
                        .font(.app(size: 16))
                        .foregroundColor(Color("TextSecondary"))
                }
                TextField("", text: $searchText)
                    .focused($focused)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
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
            }

            if !searchText.isEmpty {
                Button {
                    searchText = ""}
                label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.app(size: 18))
                        .foregroundColor(iconColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(backgroundFill)
        )
        .padding(.horizontal, 0)
        .onTapGesture { focused = true }
    }
}

struct MarketPriceFormatter {
    static let shared: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

#Preview {
    Market(viewModel: MarketViewModel())
}
