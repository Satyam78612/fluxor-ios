//
//  Wallet.swift
//  Fluxor
//
//  Created by Satyam Singh on 22/11/25.
//

import SwiftUI
import Combine
import UIKit
import CoreImage.CIFilterBuiltins

// MARK: - 0. Design System & Helpers

fileprivate extension Color {
    static let bg = Color("AppBackground")
    static let cardBg = Color("CardBackground")
    static let TextPrimary = Color("TextPrimary")
    static let TextSecondary = Color("TextSecondary")
    static let AppGreen = Color("AppGreen")
    static let AppRed = Color("AppRed")
    static let HistoryCard = Color("HistoryCard")
    static let FluxorPurple = Color("FluxorPurple")
    static let SwapCardBackground = Color("SwapCardBackground")
    static let Divider = Color.white.opacity(0.1)
}

// MARK: - 1. CHAIN REGISTRY (Single Source of Truth)

struct ChainConfig {
    let id: Int
    let name: String
    let icon: String
    let explorerBaseUrl: String
}

struct ChainRegistry {
    static let data: [Int: ChainConfig] = [
        1:     .init(id: 1,     name: "Ethereum",    icon: "ethereum", explorerBaseUrl: "https://etherscan.io/tx/"),
        56:    .init(id: 56,    name: "BNB Chain",   icon: "bnbchain",           explorerBaseUrl: "https://bscscan.com/tx/"),
        101:   .init(id: 101,   name: "Solana",      icon: "solana",        explorerBaseUrl: "https://solscan.io/tx/"),
        137:   .init(id: 137,   name: "Polygon",     icon: "polygon",       explorerBaseUrl: "https://polygonscan.com/tx/"),
        10:    .init(id: 10,    name: "Optimism",    icon: "optimism",      explorerBaseUrl: "https://optimistic.etherscan.io/tx/"),
        42161: .init(id: 42161, name: "Arbitrum",    icon: "arbitrum",      explorerBaseUrl: "https://arbiscan.io/tx/"),
        43114: .init(id: 43114, name: "Avalanche",   icon: "avalanche",     explorerBaseUrl: "https://snowtrace.io/tx/"),
        8453:  .init(id: 8453,  name: "Base",        icon: "base",          explorerBaseUrl: "https://basescan.org/tx/"),
        5000:  .init(id: 5000,  name: "Mantle",      icon: "mantle",        explorerBaseUrl: "https://mantlescan.xyz/tx/"),
        143:   .init(id: 143,   name: "Monad",       icon: "monad",         explorerBaseUrl: "https://monadscan.com/tx/"),
        999:   .init(id: 999,   name: "HyperEVM", icon: "hyperevm",   explorerBaseUrl: "https://hyperevmscan.io/tx/"),
        196:   .init(id: 196,   name: "X Layer",     icon: "xlayer",        explorerBaseUrl: "https://www.oklink.com/x-layer/tx/"),
        4200:  .init(id: 4200,  name: "Merlin",      icon: "merlin",        explorerBaseUrl: "https://scan.merlinchain.io/tx/"),
        9745:  .init(id: 9745,  name: "Plasma",      icon: "plasma",        explorerBaseUrl: "https://plasmascan.to/tx/"),
        59144: .init(id: 59144, name: "Linea",       icon: "lineachain",         explorerBaseUrl: "https://lineascan.build/tx/"),
        146:   .init(id: 146,   name: "Sonic",       icon: "sonic",        explorerBaseUrl: "https://sonicscan.org/tx/"),
        80094: .init(id: 80094, name: "Berachain",   icon: "berachain",     explorerBaseUrl: "https://berascan.com/tx/"),
        0:     .init(id: 0,     name: "Particle Chain", icon: "", explorerBaseUrl: "https://scan-mainnet-alpha.particle.network/tx/")
    ]
    
    // Helpers
    static func get(id: Int) -> ChainConfig {
        return data[id] ?? ChainConfig(id: id, name: "Unknown", icon: "circle.slash", explorerBaseUrl: "")
    }
    
    static func findByName(_ name: String) -> ChainConfig? {
        return data.values.first { $0.name.lowercased() == name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    }
}

// MARK: - Fee Estimation Helper (Mock)
struct FeeEstimator {
    static func getEstimatedNetworkFeeUSD(chainId: Int) -> Double {
        switch chainId {
        case 1:      return 4.50   // Ethereum (Expensive)
        case 56:     return 0.05   // BNB (Cheap)
        case 101:    return 0.002  // Solana (Very Cheap)
        case 137:    return 0.01   // Polygon
        case 42161:  return 0.02   // Arbitrum
        case 10:     return 0.02   // Optimism
        case 8453:   return 0.01   // Base
        case 59144:  return 0.03   // Linea
        case 80094:  return 0.15   // Berachain (Testnet/High demand example)
        default:     return 0.01   // Default cheap L2 rate
        }
    }
}

func formatFee(_ fee: Double) -> String {
    if fee == 0 { return "$0.00 USD" }
    if fee < 0.01 {
        return "$\(String(format: "%.3f", fee)) USD"
    } else {
        return "$\(String(format: "%.2f", fee)) USD"
    }
}

// MARK: - 2. GLOBAL HELPERS

func formatSmartValue(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    formatter.locale = Locale(identifier: "en_US")
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
}

func formatSmartAmount(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 18
    formatter.locale = Locale(identifier: "en_US")
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

func getExplorerURL(chainId: Int, hash: String) -> URL? {
    let config = ChainRegistry.get(id: chainId)
    guard !config.explorerBaseUrl.isEmpty else { return nil }
    return URL(string: config.explorerBaseUrl + hash)
}

func getExplorerURL(network: String, hash: String) -> URL? {
    if let config = ChainRegistry.findByName(network) {
        return URL(string: config.explorerBaseUrl + hash)
    }
    return nil
}

func networkIcon(for network: String) -> String {
    return ChainRegistry.findByName(network)?.icon ?? ""
}

func iconName(for symbol: String) -> String {
    switch symbol {
    case "SOL": return "solana"
    case "BTC": return "btc"
    case "ETH": return "eth"
    case "AAVE": return "aave"
    case "USDC": return "usdc"
    case "USDT": return "usdt"
    default: return ""
    }
}

// MARK: - 3. MODELS

struct CryptoNetwork: Identifiable, Hashable {
    var id: Int { chainId }
    
    let name: String
    let chainId: Int
    let icon: String
    let depositAddress: String
}

struct WalletTxInfo: Identifiable, Hashable {
    let id = UUID()
    let chainId: Int
    let txHash: String
}

struct WalletTransaction: Identifiable {
    let id = UUID()
    let type: TransactionType
    let symbol: String
    let status: String
    let date: String
    let mainAmount: String
    
    let price: String?
    let buyAmount: String?
    let sellAmount: String?
    let gasFee: String
    let networkChainId: Int?
    let appFee: String
    let address: String
    
    let targetTx: WalletTxInfo?
    let settlementTx: WalletTxInfo?
    let sourceTxs: [WalletTxInfo]
    
    enum TransactionType {
        case sent
        case received
        case converted
    }
}

struct WalletAsset: Identifiable, Hashable {
    var id: String { name + symbol }
    
    let icon: String
    let name: String
    let symbol: String
    let amount: Double
    let value: Double
    let dayChangeUSD: Double
    
    var isStock: Bool = false
    
    let networks: [CryptoNetwork]
    var chainSpecificBalances: [Int: Double] = [:]
    
    var primaryNetwork: CryptoNetwork? { networks.first }
    var networkName: String { primaryNetwork?.name ?? "Unknown" }
    
    func getSubNetwork(for chainId: Int) -> String {
        switch chainId {
        case 1:     return "ERC20"
        case 56:    return "BEP-20"
        case 101:   return "SPL"
        case 42161: return "Arbitrum One"
        case 43114: return "C-Chain"
        case 137:   return "Polygon PoS"
        case 999:   return "HyperEVM"
        case 10:    return "OP Mainnet"
        case 8453:  return "Base Mainnet"
        default:    return "\(ChainRegistry.get(id: chainId).name) Mainnet"
        }
    }
}

// MARK: - 4. VIEW MODEL

class WalletViewModel: ObservableObject {
    @Published var assets: [WalletAsset] = []
    @Published var transactions: [WalletTransaction] = []
    
    private var evmAddress: String = ""
    private var solanaAddress: String = ""
    
    init() {
        fetchUserAccount()
        fetchTransactions()
    }
    
    func getAddress(for chainId: Int) -> String {
        if chainId == 101 { return solanaAddress } else { return evmAddress }
    }
    
    func makeNetworks(_ ids: [Int]) -> [CryptoNetwork] {
        return ids.map { id in
            let config = ChainRegistry.get(id: id)
            return CryptoNetwork(
                name: config.name,
                chainId: config.id,
                icon: config.icon,
                depositAddress: getAddress(for: id)
            )
        }
    }
    
    func fetchTransactions() {
            self.transactions = [
                WalletTransaction(
                    type: .sent, symbol: "SOL", status: "Success", date: "8/12/25, 9:09 PM",
                    mainAmount: "-0.01473 SOL", price: nil, buyAmount: nil, sellAmount: "-0.01473 SOL",
                    gasFee: "$0.0005", networkChainId: 101, appFee: "",
                    address: "0x59714dE56e030071Bf96c7f7Ce500c05476f2C88",
                    targetTx: WalletTxInfo(chainId: 101, txHash: "E1PsV6X4ntLR7Vxg8rHEXevZ3rVqgy1zvSViCXf7MdjJj2WmnZ5QdBZwXs532RFc2KMbezTtfh8zHbLuKXNVHNN"),
                    settlementTx: WalletTxInfo(chainId: 0, txHash: "0xf0c200811eb068de3a6adcd9d0bc3c66650ac50403f2c1931002c391d14ad56a"),
                    sourceTxs: []
                ),
                WalletTransaction(
                    type: .received, symbol: "SOL", status: "Success", date: "8/12/25, 7:30 PM",
                    mainAmount: "+0.01474 SOL", price: nil, buyAmount: "+0.01474 SOL", sellAmount: nil,
                    gasFee: "$0.0005", networkChainId: 101, appFee: "",
                    address: "0x59714dE56e030071Bf96c7f7Ce500c05476f2C88",
                    targetTx: nil,
                    settlementTx: nil,
                    sourceTxs: [
                        WalletTxInfo(chainId: 101, txHash: "E1PsV6X4ntLR7Vxg8rHEXevZ3rVqgy1zvSViCXf7MdjJj2WmnZ5QdBZwXs532RFc2KMbezTtfh8zHbLuKXNVHNN")
                    ]
                ),
                WalletTransaction(
                    type: .converted, symbol: "USDT", status: "Success", date: "6/02/25, 11:10 AM",
                    mainAmount: "500 USDC", price: nil, buyAmount: "+500 USDT", sellAmount: "-500 USDC",
                    gasFee: "$0.10", networkChainId: 10, appFee: "$0.03", address: "",
                    targetTx: WalletTxInfo(chainId: 10, txHash: "0x4ea4aee4e22d7b1aba7bf63136aba80322c4a417b944b622cc23c2fbe4248880"),
                    settlementTx: WalletTxInfo(chainId: 0, txHash: "0xf0c200811eb068de3a6adcd9d0bc3c66650ac50403f2c1931002c391d14ad56a"),
                    sourceTxs: [
                        WalletTxInfo(chainId: 56, txHash: "0xa09074a6787ec48a404ef79a53b76559f69d34577f0a8aa97c14d99d7d67033c"),
                        WalletTxInfo(chainId: 42161, txHash: "0x9a2210416f1cc853f9f9842728f2aaa57d1578bec58f9472f33fbbd4e8e9c805")
                    ]
                ),
                WalletTransaction(
                    type: .received, symbol: "ETH", status: "Success", date: "8/10/25, 7:23 PM",
                    mainAmount: "+2 ETH", price: nil, buyAmount: "+2 ETH", sellAmount: nil,
                    gasFee: "$0.59", networkChainId: 1, appFee: "",
                    address: "0x59714dE56e030071Bf96c7f7Ce500c05476f2C88",
                    targetTx: nil,
                    settlementTx: WalletTxInfo(chainId: 0, txHash: "0xf0c200811eb068de3a6adcd9d0bc3c66650ac50403f2c1931002c391d14ad56a"),
                    sourceTxs: [
                        WalletTxInfo(chainId: 1, txHash: "0x9a2210416f1cc853f9f9842728f2aaa57d1578bec58f9472f33fbbd4e8e9c805")
                    ]
                )
            ]
        }
    
    func fetchUserAccount() {
        self.evmAddress = "0x59714dE56e030071Bf96c7f7Ce500c05476f2C88"
        self.solanaAddress = "AoD9S5nuShfM5vgh9XvbR6mG1CxmkP3DNhiQX2izV4Ze"
        
        self.assets = [
            .init(icon: "usdc", name: "USDC", symbol: "USDC", amount: 25000, value: 25004, dayChangeUSD: 2,
                  networks: makeNetworks([1, 101, 56, 137, 42161, 10, 8453]),
                  chainSpecificBalances: [1: 10000, 101: 5000, 56: 5000, 137: 2000, 42161: 1500, 10: 1000, 8453: 503]),
            
            .init(icon: "sol", name: "Solana", symbol: "SOL", amount: 150.04, value: 30000, dayChangeUSD: 400,
                  networks: makeNetworks([101]),
                  chainSpecificBalances: [101: 150.04]),
            
            .init(icon: "btc", name: "Bitcoin", symbol: "BTC", amount: 1.323, value: 39530.24, dayChangeUSD: 800, networks: makeNetworks([101])),
            .init(icon: "eth", name: "Ethereum", symbol: "ETH", amount: 12.532, value: 37500, dayChangeUSD: 650,networks: makeNetworks([1, 42161, 10, 8453, 59144])),
            .init(icon: "bnb", name: "BNB", symbol: "BNB", amount: 2221, value: 8800, dayChangeUSD: 120, networks: makeNetworks([56])),
            .init(icon: "hype", name: "Hyperliquid", symbol: "HYPE", amount: 1205, value: 4200, dayChangeUSD: 38, networks: makeNetworks([999])),
            .init(icon: "avax", name: "Avalanche", symbol: "AVAX", amount: 12012, value: 3000, dayChangeUSD: 25, networks: makeNetworks([43114])),
            .init(icon: "dot", name: "Polkadot", symbol: "DOT", amount: 3503, value: 2800, dayChangeUSD: 15, networks: makeNetworks([1])),
            .init(icon: "uni", name: "Uniswap", symbol: "UNI", amount: 25043, value: 2000, dayChangeUSD: -50, networks: makeNetworks([1])),
            .init(icon: "aave", name: "Aave", symbol: "AAVE", amount: 22343, value: 2440, dayChangeUSD: -521, networks: makeNetworks([1])),
            .init(icon: "usdt", name: "Tether", symbol: "USDT", amount: 0.5, value: 0.50, dayChangeUSD: 0, networks: makeNetworks([1, 56, 137, 42161])),
            .init(icon: "arb", name: "Arbitrum", symbol: "ARB", amount: 5000, value: 5000, dayChangeUSD: 50, networks: makeNetworks([42161])),
            .init(icon: "op", name: "Optimism", symbol: "OP", amount: 2000, value: 3000, dayChangeUSD: 30, networks: makeNetworks([10])),
            .init(icon: "matic", name: "Polygon", symbol: "POL", amount: 1000, value: 400, dayChangeUSD: 10, networks: makeNetworks([137])),
            .init(icon: "mon", name: "Monad", symbol: "MON", amount: 1000, value: 500, dayChangeUSD: 5, networks: makeNetworks([143])),
            .init(icon: "mnt", name: "Mantle", symbol: "MNT", amount: 594.55, value: 300, dayChangeUSD: 2, networks: makeNetworks([5000])),
            .init(icon: "linea", name: "Linea", symbol: "LINEA", amount: 32.234, value: 15040, dayChangeUSD: 10, networks: makeNetworks([59144])),
            .init(icon: "s", name: "Sonic", symbol: "S", amount: 1323130, value: 200, dayChangeUSD: 20, networks: makeNetworks([146])),
            .init(icon: "bera", name: "Berachain", symbol: "BERA", amount: 586855, value: 2500, dayChangeUSD: 100, networks: makeNetworks([80094])),
            .init(icon: "okb", name: "X Layer", symbol: "OKB", amount: 2320, value: 1000, dayChangeUSD: 5, networks: makeNetworks([196])),
            .init(icon: "merlin", name: "Merlin", symbol: "MERL", amount: 2000, value: 1200, dayChangeUSD: 15,  networks: makeNetworks([4200])),
            .init(icon: "xpl", name: "Plasma", symbol: "PLASMA", amount: 5000, value: 100, dayChangeUSD: 0, networks: makeNetworks([9745])),
            .init(icon: "tslax", name: "Tesla", symbol: "TSLA", amount: 586855, value: 22200, dayChangeUSD: 100, isStock: true, networks: makeNetworks([80094])),
            .init(icon: "hoodx", name: "Robinhood", symbol: "HOOD", amount: 2950, value: 12300, dayChangeUSD: 5, isStock: true, networks: makeNetworks([196])),
            .init(icon: "mstrx", name: "MicroStrategy", symbol: "MSTR", amount: 2000, value: 12000, dayChangeUSD: 15, isStock: true, networks: makeNetworks([4200])),
            .init(icon: "crclx", name: "Circle", symbol: "CRCL", amount: 5000, value: 10000, dayChangeUSD: 0, isStock: true, networks: makeNetworks([9745]))
        
        ]
    }
}

// MARK: - 5. MAIN WALLET VIEW

struct Wallet: View {
    @StateObject private var viewModel = WalletViewModel()
    
    @State private var selectedCategory = "Overview"
    @State private var isShowingSearch = false
    @State private var isShowingHistory = false
    @State private var isShowingDeposit = false
    @State private var isShowingWithdraw = false
    @State private var isShowingConvert = false
    @State private var hideSmallAssets = false
    @State private var showFilterCard = false
    
    var sortedAssets: [WalletAsset] {
        let valueFiltered = hideSmallAssets ? viewModel.assets.filter { $0.value >= 1.0 } : viewModel.assets
        
        let categoryFiltered: [WalletAsset]
        if selectedCategory == "Crypto" {
            categoryFiltered = valueFiltered.filter { !$0.isStock }
        } else if selectedCategory == "Stocks" {
            categoryFiltered = valueFiltered.filter { $0.isStock }
        } else {
            categoryFiltered = valueFiltered
        }
        
        return categoryFiltered.sorted { $0.value > $1.value }
    }
    
    var totalBalance: Double { viewModel.assets.reduce(0) { $0 + $1.value } }
    var todayPNL: Double { viewModel.assets.reduce(0) { $0 + $1.dayChangeUSD } }
    var todayPNLPercent: Double {
        let startOfDay = totalBalance - todayPNL
        guard startOfDay > 0 else { return 0 }
        return (todayPNL / startOfDay) * 100
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        WalletBalanceCard(
                            totalBalance: totalBalance,
                            todayPNL: todayPNL,
                            todayPNLPercent: todayPNLPercent,
                            onHistoryTap: { isShowingHistory = true }
                        )
                        WalletActionButtons(
                            onDepositTap: { isShowingDeposit = true },
                            onWithdrawTap: { isShowingWithdraw = true },
                            onConvertTap: { isShowingConvert = true }
                        )
                        
                        VStack(alignment: .leading, spacing: -3) {
                            
                            HStack(spacing: 15) {
                                ForEach(["Overview", "Crypto", "Stocks"], id: \.self) { category in
                                    
                                 VStack(spacing: 0) {
                                    Text(category)
                                        .font(.app(size: 18, weight: .semibold))
                                        .foregroundColor(selectedCategory == category ? .TextPrimary : .TextSecondary)
                                        
                                    Rectangle()
                                        .fill(Color.TextPrimary)
                                        .frame(width: 20, height: 2)
                                        .padding(.top, 7.8)
                                        .cornerRadius(2)
                                        .opacity(selectedCategory == category ? 1 : 0)
                                       }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                              selectedCategory = category
                                       }
                                }
                                Spacer()
                                                                
                                Button(action: { isShowingSearch = true }) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.TextSecondary)
                                        .padding(.bottom, 7)
                                    
                                }.buttonStyle(.plain)
                                
                                Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { showFilterCard.toggle() } }) {
                                    Image("Hexagon")
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaledToFit()
                                        .frame(width: 42.5, height: 42.5)
                                        .foregroundColor(showFilterCard ? .TextPrimary : .TextSecondary)
                                        .padding(.horizontal, -12)
                                        .padding(.leading, 6)
                                        .padding(.bottom, 8)
                                    
                                }.buttonStyle(.plain)
                            }
                            .overlay(alignment: .topTrailing) {
                                if showFilterCard {
                                    HStack {
                                        Text("Hide assets <1 USD").font(.app(size: 14, weight: .medium)).foregroundColor(.TextPrimary)
                                        Spacer()
                                        Image(systemName: hideSmallAssets ? "checkmark.square.fill" : "square").font(.system(size: 16)).foregroundColor(hideSmallAssets ? .yellow : .TextSecondary)
                                    }
                                    .padding(.vertical, 12).padding(.horizontal, 16).frame(width: 200).background(Color.bg).cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.TextSecondary.opacity(0.2), lineWidth: 1))
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                    .offset(y: 45)
                                    .onTapGesture { withAnimation { hideSmallAssets.toggle() } }
                                }
                            }
                            .zIndex(100).padding(.horizontal, 13).padding(.bottom, -1).padding(.top, -12)
                            
                            Divider()
                                .overlay(Color.TextPrimary.opacity(0.2))
                                .padding(.top, -7.5)
                                .padding(.bottom, 1)
                                .padding(.horizontal, 13)
                            
                            VStack(spacing: 0) {
                                ForEach(sortedAssets) { asset in
                                    NavigationLink(value: asset) {
                                        WalletAssetRow(asset: asset).contentShape(Rectangle())
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4).padding(.bottom, 40).padding(.top, -10)
                }
            }
            .onTapGesture { if showFilterCard { withAnimation { showFilterCard = false } } }
            .navigationDestination(isPresented: $isShowingDeposit) {
                DepositView(assets: viewModel.assets).navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $isShowingWithdraw) {
                WithdrawView(assets: viewModel.assets).navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $isShowingConvert) {
                ConvertView(assets: viewModel.assets).navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $isShowingSearch) {
                TokenSearchPage(assets: viewModel.assets, transactions: viewModel.transactions).navigationBarBackButtonHidden(true)
            }
            .navigationDestination(for: WalletAsset.self) { asset in
                TokenDetailView(asset: asset, allTransactions: viewModel.transactions)
            }
            .navigationDestination(isPresented: $isShowingHistory) {
                HistoryView(transactions: viewModel.transactions).navigationBarBackButtonHidden(true)
            }
        }
    }
}

// MARK: - 6. HISTORY VIEW

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    let transactions: [WalletTransaction]
    @State private var selectedTransaction: WalletTransaction?
    @State private var contentHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
           
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.TextPrimary)
                    }
                    Spacer()
                    Text("History")
                        .font(.app(size: 20, weight: .semibold))
                        .foregroundColor(.TextPrimary)
                    Spacer()
                    Image(systemName: "arrow.left").opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 20)
              
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(spacing: 12) {
                            ForEach(transactions) { transaction in
                                WalletTransactionRow(transaction: transaction)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedTransaction = transaction
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
        .sheet(item: $selectedTransaction) { transaction in
            WalletTransactionDetail(item: transaction, contentHeight: $contentHeight)
                .presentationDetents([
                    .height(min(max(100 + contentHeight, 180), UIScreen.main.bounds.height * 0.9))
                ])
                .presentationDragIndicator(.visible)
                .presentationBackground(.clear)
        }
    }
}

// MARK: - 7. REUSABLE NETWORK SELECTOR

struct NetworkSelectorView: View {
    let networks: [CryptoNetwork]
    @Binding var selectedNetwork: CryptoNetwork?
    @State private var isOpen = false

    private let rowHeight: CGFloat = 56
    private let visibleRows: CGFloat = 5
    private let inputBgColor = Color.white.opacity(0.05)

    private var activeNetwork: CryptoNetwork? {
        selectedNetwork ?? networks.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Network")
                .font(.app(size: 16))
                .foregroundColor(.TextSecondary)

            Button {
                isOpen.toggle()
            } label: {
                HStack(spacing: 8) {
                    if let network = activeNetwork {
                        Image(network.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                    }

                    Text(activeNetwork?.name ?? "Select Network")
                        .font(.app(size: 18, weight: .semibold))
                        .foregroundColor(.TextPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.TextSecondary)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.TextSecondary.opacity(0.10)))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .overlay(alignment: .top) {
                if isOpen {
                    dropdownList
                        .offset(y: 60)
                        .zIndex(100)
                }
            }
        }
        .onTapGesture {
            if isOpen { isOpen = false }
        }
    }

    private var dropdownList: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(networks) { network in
                        Button {
                            selectedNetwork = network
                            isOpen = false
                        } label: {
                            HStack(spacing: 8) {
                                Image(network.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())

                                Text(network.name)
                                    .font(.app(size: 18, weight: .semibold))
                                    .foregroundColor(.TextPrimary)

                                Spacer()

                                if activeNetwork?.id == network.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: rowHeight)
                        }
                        .buttonStyle(.plain)

                        if network.id != networks.last?.id {
                            Divider().background(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
        .frame(
            height: min(CGFloat(networks.count) * rowHeight, rowHeight * visibleRows)
        )
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.5), radius: 15, y: 10)
    }
}

// MARK: - 8. TRANSACTION DETAIL

struct WalletTransactionDetail: View {
    let item: WalletTransaction
    @Binding var contentHeight: CGFloat
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            
            VStack(spacing: 8) {
                // Header
                HStack {
                    Spacer()
                    Text("Transaction Details")
                        .font(.app(size: 18, weight: .semibold))
                        .foregroundColor(.TextPrimary)
                    Spacer()
                   
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.gray.opacity(0.6))
                    }
                }
                .padding()
              
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                      
                        // Icon + Title + Status
                        VStack(spacing: 14) {
                            HStack(spacing: 6) {
                                Image(iconName(for: item.symbol))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 27, height: 27)
                                    .clipShape(Circle())
                               
                                Text(item.symbol)
                                    .font(.app(size: 20, weight: .semibold))
                                    .foregroundColor(.TextPrimary)
                               
                                Spacer()
                               
                                Text(displayType)
                                    .font(.app(size: 18, weight: .semibold))
                                    .foregroundColor(.TextPrimary)
                               
                                Text(item.status)
                                    .font(.app(size: 15, weight: .semibold))
                                    .foregroundColor(.AppGreen)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.AppGreen.opacity(0.2))
                                    .cornerRadius(15)
                            }
                           
                            Divider().background(Color.white.opacity(0.2))
                           
                            Group {
                                detailRow(label: "Time", value: formatDate(item.date))
                               
                                if let price = item.price, !price.isEmpty {
                                    detailRow(label: "Price", value: price)
                                }
                               
                                switch item.type {
                                case .sent:
                                    if let amt = item.sellAmount {
                                        detailRow(label: "Token", value: amt, valueColor: .AppRed)
                                    }
                                    addressRow(label: "To", address: item.address)
                                   
                                case .received:
                                    if let amt = item.buyAmount {
                                        detailRow(label: "Token", value: amt, valueColor: .AppGreen)
                                    }
                                    addressRow(label: "From", address: item.address)
                                   
                                case .converted:
                                    if let buy = item.buyAmount {
                                        detailRow(label: "Buy", value: buy, valueColor: .AppGreen)
                                    }
                                    if let sell = item.sellAmount {
                                        detailRow(label: "Using", value: sell, valueColor: .AppRed)
                                    }
                                }
                               
                                detailRow(label: "Gas Fee", value: item.gasFee)
                               
                                // Network Row (Using ID Lookup)
                                if let chainId = item.networkChainId {
                                    let config = ChainRegistry.get(id: chainId)
                                    networkRow(label: "Network", network: config.name, icon: config.icon)
                                }
                            }
                        }
                        .padding(5)
                       
                        // Hash Sections (Updated for IDs)
                        VStack(spacing: 0) {
                            if let target = item.targetTx {
                                hashBlock(title: "Target Tx Hash on", chainId: target.chainId, hash: target.txHash)
                                if item.settlementTx != nil || !item.sourceTxs.isEmpty {
                                    Divider().background(Color.white.opacity(0.1))
                                }
                            }
                           
                            if let settlement = item.settlementTx {
                                hashBlock(title: "Settlement Tx Hash on", chainId: settlement.chainId, hash: settlement.txHash)
                                    .padding(.top, (item.targetTx != nil) ? 0 : 0)
                                if !item.sourceTxs.isEmpty {
                                    Divider().background(Color.white.opacity(0.1))
                                }
                            }
                           
                            ForEach(Array(item.sourceTxs.enumerated()), id: \.element.id) { index, source in
                                hashBlock(title: "From Tx Hash on", chainId: source.chainId, hash: source.txHash)
                                if index < item.sourceTxs.count - 1 {
                                    Divider().background(Color.white.opacity(0.1))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 5)
                    .background(
                        GeometryReader { g in
                            Color.clear.preference(key: WalletViewHeightKey.self, value: g.size.height)
                        }
                    )
                }
            }
        }
        .onPreferenceChange(WalletViewHeightKey.self) { newH in
            if abs(newH - contentHeight) > 0.5 {
                contentHeight = newH
            }
       }
    }
    
    // MARK: - Transaction Detail Helpers
    
    var displayType: String {
        switch item.type {
        case .sent: return "Sent"
        case .received: return "Received"
        case .converted: return "Converted"
        }
    }
    
    func detailRow(label: String, value: String, valueColor: Color = .TextPrimary) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.TextSecondary)
                .font(.app(size: 18, weight: .semibold))
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .font(.app(size: 18, weight: .semibold))
        }
    }
    
    func networkRow(label: String, network: String, icon: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.TextSecondary)
                .font(.app(size: 18, weight: .semibold))
            Spacer()
            HStack(spacing: 6) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .clipShape(Circle())
              
                Text(network)
                    .foregroundColor(.TextPrimary)
                    .font(.app(size: 18, weight: .medium))
            }
        }
    }
    
    func addressRow(label: String, address: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.TextSecondary)
                .font(.app(size: 18, weight: .semibold))
            Spacer()
            CopyableAddressView(fullAddress: address)
        }
    }
    
    // ✅ CORRECT: Takes ChainID, resolves Name/URL internally
    func hashBlock(title: String, chainId: Int, hash: String) -> some View {
        let chainConfig = ChainRegistry.get(id: chainId)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.app(size: 17, weight: .semibold))
                    .foregroundColor(.TextPrimary)
              
                Text(chainConfig.name)
                    .font(.app(size: 17, weight: .semibold))
                    .foregroundColor(.TextPrimary)
            }
          
            HStack {
                Text("Tx Hash")
                    .foregroundColor(.TextSecondary)
                    .font(.app(size: 16))
                Spacer()
              
                let hashContent = HStack(spacing: 4) {
                    Text(shortenHash(hash))
                        .foregroundColor(.TextSecondary)
                        .font(.app(size: 16))
                   
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 15))
                        .foregroundColor(.TextSecondary)
                }
              
                // ✅ Safe Explorer Link Generation
                if let url = getExplorerURL(chainId: chainId, hash: hash) {
                    Link(destination: url) {
                        hashContent
                    }
                } else {
                    hashContent
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 4)
    }
    
    func shortenHash(_ hash: String) -> String {
        guard hash.count > 12 else { return hash }
        return hash.prefix(5) + "..." + hash.suffix(4)
    }
    
    func formatDate(_ originalDate: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "d/M/yy, h:mm a"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
       
        if let date = inputFormatter.date(from: originalDate) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "d MMM yyyy, HH:mm"
            return outputFormatter.string(from: date)
        }
        return originalDate
    }
}

struct UnifiedSearchBar: View {
    @Binding var searchText: String
    var placeholder: String
    @FocusState private var focused: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.app(size: 16))
                .foregroundColor(.TextSecondary)

            TextField(placeholder, text: $searchText)
                .font(.app(size: 16))
                .foregroundColor(.TextPrimary)
                .accentColor(.TextPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focused)
           
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.TextSecondary)
                }
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(backgroundFill)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.06), radius: focused ? 8 : 4, y: focused ? 4 : 2)
        .onTapGesture { focused = true }
    }
}

// MARK: - New Component: Copyable Address View

struct CopyableAddressView: View {
    let fullAddress: String
    @State private var showCopied = false
    
    var shortAddress: String {
        guard fullAddress.count > 8 else { return fullAddress }
        return "\(fullAddress.prefix(4))...\(fullAddress.suffix(4))"
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(shortAddress)
                .foregroundColor(.TextPrimary)
                .font(.app(size: 18))
           
            ZStack {
                Button(action: {
                    copyToClipboard()
                }) {
                    if showCopied {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 26, height: 26)
                           
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                    } else {
                        Image("CopyButton")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.TextSecondary)
                            .scaledToFit()
                            .frame(width: 43, height: 43)
                    }
                }
                .buttonStyle(.borderless)
                .frame(width: 43, height: 43)
              
                if showCopied {
                    VStack(spacing: -1) {
                        Text("Copied!")
                            .font(.app(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .cornerRadius(5)
                            .fixedSize()
                       
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(180))
                            .offset(y: -1)
                    }
                    .offset(y: -28)
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(1)
                }
            }
            .frame(width: 20, height: 20)
        }
    }
    
    func copyToClipboard() {
        UIPasteboard.general.string = fullAddress
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopied = false
            }
        }
    }
}

struct WalletBalanceCard: View {
    let totalBalance: Double
    let todayPNL: Double
    let todayPNLPercent: Double
    var onHistoryTap: () -> Void
    var isPositive: Bool { todayPNL >= 0 }
    var pnlColor: Color { isPositive ? .AppGreen : .AppRed }
    var pnlSign: String { isPositive ? "+" : "" }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            // 1. The Balance & PnL (Centered)
            VStack(spacing: 18) {
                Text("Total Balance")
                    .font(.app(size: 17, weight: .medium))
                    .foregroundColor(.TextSecondary)
                    .padding(.top,-4)
                
                Text("$\(formatSmartValue(totalBalance))")
                    .font(.app(size: 32, weight: .bold))
                    .foregroundColor(.TextPrimary)
                
                    HStack(spacing: 5) {
                        
                        Text("Today's PnL")
                            .font(.app(size: 16, weight: .medium))
                            .foregroundColor(.TextSecondary)
                        
                        Button(action: {
                            print("PnL Value Tapped!")
                        }) {
                            Text("\(pnlSign)$\(formatSmartValue(todayPNL)) (\(pnlSign)\(String(format: "%.2f", todayPNLPercent))%)")
                                .font(.app(size: 16, weight: .medium))
                                .foregroundColor(pnlColor)
                    }
                    .buttonStyle(.plain)
                }
                .buttonStyle(.plain)
                .padding(.top, -10)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            
            // 2. The History Button (Top Right)
            Button(action: onHistoryTap) {
                Image("HistoryCard")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.TextPrimary)
            }
            .padding(.top, 0)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 20)
        .padding(.bottom, -25)
    }
}

struct WalletViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct WalletActionButtons: View {
    var onDepositTap: (() -> Void)? = nil
    var onWithdrawTap: (() -> Void)? = nil
    var onConvertTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            WalletActionButton(title: "Deposit", color: Color.FluxorPurple) {
                onDepositTap?()
            }
           
            WalletActionButton(title: "Withdraw", color: .TextPrimary) {
                onWithdrawTap?()
            }
           
            WalletActionButton(title: "Convert", color: .TextPrimary) {
                onConvertTap?()
            }
        }
        .padding(.horizontal, 12)
    }
}

struct WalletActionButton: View {
    let title: String
    let color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.app(size: 17, weight: .semibold))
                .foregroundColor(Color("CardBackground"))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(color)
                .cornerRadius(15)
        }
    }
}

struct WalletAssetRow: View {
    let asset: WalletAsset
    var body: some View {
        HStack(spacing: 9) {
            Image(asset.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)
                .clipShape(Circle())
           
            VStack(alignment: .leading, spacing: 2.5) {
                Text(asset.name).font(.app(size: 17, weight: .semibold)).foregroundColor(.TextPrimary)
                Text(asset.symbol).font(.app(size: 15, weight: .medium)).foregroundColor(.TextSecondary)
            }
            Spacer()
           
            VStack(alignment: .trailing, spacing: 2.5) {
                Text(formatSmartAmount(asset.amount)).font(.app(size: 17, weight: .semibold)).foregroundColor(.TextPrimary)
              
                Text("$\(formatSmartValue(asset.value))").font(.app(size: 15, weight: .medium)).foregroundColor(.TextSecondary)
            }
        }.padding(.horizontal, 13).padding(.vertical, 11)
    }
}

struct WalletTransactionRow: View {
    let transaction: WalletTransaction
    
    var title: String {
        switch transaction.type {
        case .sent: return "Sent"
        case .received: return "Received"
        case .converted: return "Converted"
        }
    }
    
    var amountColor: Color {
        switch transaction.type {
        case .sent: return .AppRed
        case .received: return .AppGreen
        case .converted: return .TextPrimary
        }
    }
    
    var iconName: String {
        switch transaction.symbol {
        case "SOL": return "sol"
        case "BTC": return "btc"
        case "ETH": return "eth"
        case "AAVE": return "aave"
        case "USDC": return "usdc"
        case "USDT": return "usdt"
        default: return ""
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
           
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.app(size: 17, weight: .semibold))
                    .foregroundColor(.TextPrimary)
              
                Text(formatListDate(transaction.date))
                    .font(.app(size: 14, weight: .medium))
                    .foregroundColor(.TextSecondary)
            }
           
            Spacer()
           
            Text(transaction.mainAmount)
                .font(.app(size: 16, weight: .medium))
                .foregroundColor(amountColor)
        }
        .padding(16)
        .background(Color.HistoryCard)
        .cornerRadius(20)
    }
    
    func formatListDate(_ dateStr: String) -> String {
        let input = DateFormatter()
        input.dateFormat = "d/M/yy, h:mm a"
        if let date = input.date(from: dateStr) {
            let output = DateFormatter()
            output.dateFormat = "yyyy-MM-dd HH:mm"
            return output.string(from: date)
        }
        return dateStr
    }
}

struct TokenSearchPage: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    let assets: [WalletAsset]
    let transactions: [WalletTransaction]
    var filteredAssets: [WalletAsset] {
        if searchText.isEmpty { return assets }
        return assets.filter { asset in asset.name.localizedCaseInsensitiveContains(searchText) || asset.symbol.localizedCaseInsensitiveContains(searchText) }
    }
    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) { Image(systemName: "chevron.left").font(.app(size: 20, weight: .medium)).foregroundColor(.TextPrimary).frame(width: 30, height: 30) }
                   
                    UnifiedSearchBar(searchText: $searchText, placeholder: "Token name")
                        .padding(.trailing, 2)
                   
                }.padding(.horizontal, 11).padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(filteredAssets) { asset in
                            NavigationLink(destination: TokenDetailView(asset: asset, allTransactions: transactions)) {
                                WalletAssetRow(asset: asset)
                                    .contentShape(Rectangle())
                               }
                          .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.top, 10)
        }
    }
}

struct TokenDetailView: View {
    let asset: WalletAsset
    let allTransactions: [WalletTransaction]
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: String = "Chains"
    @State private var selectedTransaction: WalletTransaction?
    @State private var contentHeight: CGFloat = 0
    @State private var isShowingReceive = false
    @State private var isShowingSend = false
    
    var specificHistory: [WalletTransaction] {
        allTransactions.filter { transaction in
            if transaction.symbol == asset.symbol {
                return true
            }
            if transaction.type == .converted {
                if transaction.mainAmount.contains(asset.symbol) { return true }
                if let buy = transaction.buyAmount, buy.contains(asset.symbol) { return true }
                if let sell = transaction.sellAmount, sell.contains(asset.symbol) { return true }
            }
            return false
        }
    }
    
    var chainBalances: [(network: CryptoNetwork, amount: String)] {
        asset.networks.map { network in
            let specificAmount = asset.chainSpecificBalances[network.chainId] ?? 0.0
            return (
                network: network,
                amount: formatSmartAmount(specificAmount)
            )
        }
    }

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
           
            VStack(spacing: -2) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.TextPrimary)
                    }
                    Spacer()
                   
                    HStack(spacing: 6) {
                        Image(asset.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .clipShape(Circle())
                      
                        Text(asset.name)
                            .font(.app(size: 22, weight: .bold))
                            .foregroundColor(.TextPrimary)
                    }
                   
                    Spacer()
                   
                    Image(systemName: "arrow.left").opacity(0).frame(width: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
              
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Balance")
                                    .font(.app(size: 16, weight: .medium))
                                    .foregroundColor(.TextSecondary)
                            }
                            
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(formatSmartAmount(asset.amount))
                                    .font(.app(size: 35, weight: .bold))
                                    .foregroundColor(.TextPrimary)
                                
                                Text("$\(formatSmartValue(asset.value))")
                                    .font(.app(size: 16, weight: .medium))
                                    .foregroundColor(.TextSecondary)
                                    .padding(.bottom, 4)
                            }
                            
                            HStack(spacing: 40) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Available")
                                        .font(.app(size: 14))
                                        .foregroundColor(.TextSecondary)
                                    Text(formatSmartAmount(asset.amount))
                                        .font(.app(size: 16, weight: .medium))
                                        .foregroundColor(.TextPrimary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Unavailable")
                                        .font(.app(size: 14))
                                        .foregroundColor(.TextSecondary)
                                    Text("0.00")
                                        .font(.app(size: 16, weight: .medium))
                                        .foregroundColor(.TextPrimary)
                                }
                            }
                            .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        
                        HStack(spacing: 12) {
                            TokenActionButton(icon: "Send", text: "Send") {
                                isShowingSend = true
                            }
                            
                            TokenActionButton(icon: "Receive", text: "Receive") {
                                isShowingReceive = true
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, -4)
                        
                        HStack(spacing: 25) {
                            TabButton(title: "Chains", selectedTab: $selectedTab)
                            TabButton(title: "History", selectedTab: $selectedTab)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, -4)
                        
                        Group {
                            if selectedTab == "Chains" {
                                if chainBalances.isEmpty {
                                    VStack(spacing: 10) {
                                        Text("No networks available")
                                            .font(.app(size: 16))
                                            .foregroundColor(.TextSecondary)
                                    }
                                    .padding(.top, 20)
                                } else {
                                    VStack(spacing: 22) {
                                        ForEach(chainBalances, id: \.network.id) { item in
                                            HStack {
                                                Image(item.network.icon)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 30, height: 30)
                                                    .clipShape(Circle())
                                                
                                                Text(item.network.name)
                                                    .font(.app(size: 19, weight: .medium))
                                                    .foregroundColor(.TextPrimary)
                                                    .padding(.leading, 1)
                                                
                                                Spacer()
                                                
                                                Text(item.amount)
                                                    .font(.app(size: 19, weight: .medium))
                                                    .foregroundColor(.TextPrimary)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 40)
                                    .padding(.top, -8)
                                }
                                
                            } else {
                                if specificHistory.isEmpty {
                                    VStack(spacing: 20) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 40))
                                            .foregroundColor(.TextSecondary)
                                        Text("No recent \(asset.symbol) history")
                                            .font(.app(size: 16))
                                            .foregroundColor(.TextSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 40)
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(specificHistory) { transaction in
                                            WalletTransactionRow(transaction: transaction)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    selectedTransaction = transaction
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 40)
                                    .padding(.top, -10)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isShowingReceive) {
            DepositDetailsView(asset: asset)
                .navigationBarBackButtonHidden(true)
        }
        .navigationDestination(isPresented: $isShowingSend) {
            WithdrawDetailsView(asset: asset)
                .navigationBarBackButtonHidden(true)
        }
        .sheet(item: $selectedTransaction) { transaction in
            WalletTransactionDetail(item: transaction, contentHeight: $contentHeight)
                .presentationDetents([
                    .height(min(max(100 + contentHeight, 180), UIScreen.main.bounds.height * 0.9))
                ])
                .presentationDragIndicator(.visible)
                .presentationBackground(.clear)
        }
    }
}

struct TabButton: View {
    let title: String
    @Binding var selectedTab: String
    
    var isSelected: Bool {
        selectedTab == title
    }
    
    var body: some View {
        Button(action: {
            selectedTab = title
        }) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.app(size: 18, weight: isSelected ? .semibold : .semibold))
                    .foregroundColor(isSelected ? .TextPrimary : .TextSecondary)
              
                if isSelected {
                    Rectangle()
                        .fill(Color.TextPrimary)
                        .frame(width: 15, height: 2)
                        .cornerRadius(10)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 3)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct TokenActionButton: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Spacer()
                Image(icon)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                Text(text)
                    .font(.app(size: 19, weight: .semibold))
                    .padding(.leading, 1)
                Spacer()
            }
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.TextSecondary.opacity(0.08))
            )
            .foregroundColor(.TextPrimary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DepositView: View {
    @Environment(\.dismiss) var dismiss
    let assets: [WalletAsset]
    @State private var searchText = ""
    
    var filteredAssets: [WalletAsset] {
        if searchText.isEmpty { return assets }
        return assets.filter { asset in
            asset.name.localizedCaseInsensitiveContains(searchText) ||
            asset.symbol.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.TextPrimary)
                    }
                    Spacer()
                    Text("Select Coin")
                        .font(.app(size: 20, weight: .semibold))
                        .foregroundColor(Color.TextPrimary)
                    Spacer()
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                        .opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 15)
              
                UnifiedSearchBar(searchText: $searchText, placeholder: "Search Coins")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
              
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(filteredAssets) { asset in
                            NavigationLink(destination: DepositDetailsView(asset: asset)) {
                                DepositAssetRow(asset: asset)
                            }
                            .buttonStyle(.plain)
                           
                            Divider()
                                .background(Color.white.opacity(0.05))
                                .padding(.leading, 16)
                                .padding(.trailing, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct StrictDecimalField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var uiFont: UIFont?
    var color: UIColor
    var maxAmount: Double? = nil
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .decimalPad
        textField.placeholder = placeholder
        textField.tintColor = UIColor(named: "TextPrimary")
        textField.font = uiFont ?? .systemFont(ofSize: 17)
        textField.textColor = color
        textField.textAlignment = .left
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        if uiView.text != text {
            uiView.text = text
        }
        uiView.font = uiFont
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: StrictDecimalField

        init(_ parent: StrictDecimalField) {
            self.parent = parent
            
        }
        
        @objc func textFieldDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            
            if string.isEmpty { return true }
        
            let separatorSet = CharacterSet(charactersIn: ".,")
            let numberSet = CharacterSet(charactersIn: "0123456789")
            let allowedSet = numberSet.union(separatorSet)

            if string.rangeOfCharacter(from: allowedSet.inverted) != nil {
                return false
            }
            
            let incomingIsSeparator = string.rangeOfCharacter(from: separatorSet) != nil
            let existingHasSeparator = currentText.rangeOfCharacter(from: separatorSet) != nil
            
            if incomingIsSeparator && existingHasSeparator {
                return false
            }
            
            if let max = parent.maxAmount {
                let futureString = (currentText as NSString).replacingCharacters(in: range, with: string)
                let cleanString = futureString.replacingOccurrences(of: ",", with: ".")
                
                if let futureValue = Double(cleanString) {
                    if futureValue > max {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        return false
                    }
                }
            }
            
            return true
        }
    }
}

struct DepositAssetRow: View {
    let asset: WalletAsset
    
    var body: some View {
        HStack(spacing: 10) {
            Image(asset.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)
                .clipShape(Circle())
           
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .font(.app(size: 17, weight: .semibold))
                    .foregroundColor(.TextPrimary)
              
                Text(asset.symbol)
                    .font(.app(size: 15, weight: .medium))
                    .foregroundColor(.TextSecondary)
            }
           
            Spacer()
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct DepositDetailsView: View {
    let asset: WalletAsset
    @Environment(\.dismiss) var dismiss

    @State private var selectedNetwork: CryptoNetwork?

    var activeNetwork: CryptoNetwork? {
        selectedNetwork ?? asset.networks.first
    }

    var currentAddress: String {
        activeNetwork?.depositAddress ?? ""
    }

    let inputBgColor = Color.white.opacity(0.05)

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.TextPrimary)
                    }

                    Spacer()

                    Text("Receive \(asset.symbol)")
                        .font(.app(size: 20, weight: .semibold))
                        .foregroundColor(Color.TextPrimary)

                    Spacer()

                    Image(systemName: "arrow.left")
                        .opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 15)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .frame(width: 230, height: 230)
                                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                            if !currentAddress.isEmpty {
                                FluxorQRView(payload: currentAddress)
                                    .frame(width: 200, height: 200)
                            } else {
                                ProgressView()
                            }
                        }
                        .padding(.top, 10)

                        NetworkSelectorView(networks: asset.networks, selectedNetwork: $selectedNetwork)
                            .padding(.horizontal, 16)
                            .zIndex(10)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Deposit Address")
                                .font(.app(size: 16))
                                .foregroundColor(Color.TextSecondary)

                            HStack(alignment: .top, spacing: 12) {
                                Text(currentAddress)
                                    .font(.app(size: 16, weight: .medium))
                                    .foregroundColor(Color.TextPrimary)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Button {
                                    UIPasteboard.general.string = currentAddress
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                } label: {
                                    Image("CopyButton")
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaledToFit()
                                        .frame(width: 44, height: 44)
                                        .foregroundColor(Color.TextSecondary)
                                        .cornerRadius(10)
                                        .padding(.top, -4)
                                        .padding(.bottom, -15)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.TextSecondary.opacity(0.10)))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        .zIndex(5)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if selectedNetwork == nil {
                selectedNetwork = asset.networks.first
            }
        }
    }
}

struct FluxorQRView: View {
    let payload: String

    var body: some View {
        if let image = generateQRImage(from: payload) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            ProgressView()
        }
    }

    private func generateQRImage(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H"

        guard let outputImage = filter.outputImage else { return nil }
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

struct WithdrawView: View {
    @Environment(\.dismiss) var dismiss
    let assets: [WalletAsset]
    @State private var searchText = ""
    
    var filteredAssets: [WalletAsset] {
        let list = searchText.isEmpty ? assets : assets.filter { asset in
            asset.name.localizedCaseInsensitiveContains(searchText) ||
            asset.symbol.localizedCaseInsensitiveContains(searchText)
        }
        return list.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.TextPrimary)
                    }
                    Spacer()
                    Text("Select Coin")
                        .font(.app(size: 20, weight: .semibold))
                        .foregroundColor(Color.TextPrimary)
                    Spacer()
                    Image(systemName: "arrow.left").opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 15)
              
                UnifiedSearchBar(searchText: $searchText, placeholder: "Search Coins")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
              
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(filteredAssets) { asset in
                            NavigationLink(destination: WithdrawDetailsView(asset: asset)) {
                                WalletAssetRow(asset: asset)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4.5)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct WithdrawDetailsView: View {
    let asset: WalletAsset
    @Environment(\.dismiss) var dismiss
    
    @State private var address: String = ""
    @State private var amount: String = ""
    @State private var selectedNetwork: CryptoNetwork?
    
    let inputBgColor = Color.white.opacity(0.05)
    
    var activeNetwork: CryptoNetwork? {
        selectedNetwork ?? asset.networks.first
    }
    
    var availableBalanceString: String {
        return "\(formatSmartAmount(asset.amount)) \(asset.symbol)"
    }
    
    var networkFeeUSD: Double {
        guard let network = activeNetwork else { return 0.0 }
        return FeeEstimator.getEstimatedNetworkFeeUSD(chainId: network.chainId)
    }
    
    var receiveAmount: Double {
        guard let inputVal = Double(amount) else { return 0.0 }
        return inputVal > 0 ? inputVal : 0.0
    }

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
           
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.TextPrimary)
                    }
                    Spacer()
                    Text("Send \(asset.symbol)")
                        .font(.app(size: 20, weight: .semibold))
                        .foregroundColor(Color.TextPrimary)
                    Spacer()
                    Image(systemName: "arrow.left").opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 20)
              
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                      
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Address")
                                .font(.app(size: 16))
                                .foregroundColor(Color.TextSecondary)
                           
                            TextField("Enter Wallet Address", text: $address)
                                .font(.app(size: 16))
                                .foregroundColor(Color.TextPrimary)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.TextSecondary.opacity(0.10)))
                                .cornerRadius(12)
                                .submitLabel(.next)
                        }
                      
                        NetworkSelectorView(networks: asset.networks, selectedNetwork: $selectedNetwork)
                            .zIndex(100)
                      
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Withdrawal Amount")
                                    .font(.app(size: 16))
                                    .foregroundColor(Color.TextSecondary)
                                Spacer()
                            }
                           
                            HStack {
                                StrictDecimalField(
                                    text: $amount,
                                    placeholder: "\(asset.symbol) Amount",
                                    uiFont: UIFont(name: "Inter-Medium", size: 17.5) ?? .systemFont(ofSize: 17.5, weight: .medium),
                                    color: UIColor(Color.TextPrimary),
                                    maxAmount: asset.amount
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 19)
                               
                                Spacer()
                               
                                Button(action: {
                                    amount = formatSmartAmount(asset.amount).replacingOccurrences(of: ",", with: "")
                                }) {
                                    Text("Max")
                                        .font(.app(size: 15, weight: .bold))
                                        .foregroundColor(Color.TextPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.TextSecondary.opacity(0.10)))
                            .cornerRadius(12)
                           
                            HStack {
                                Text("Available")
                                    .font(.app(size: 14))
                                    .foregroundColor(Color.TextSecondary)
                               
                                Spacer()
                               
                                Text(availableBalanceString)
                                    .font(.app(size: 14))
                                    .foregroundColor(Color.TextPrimary)
                            }
                        }
                        .zIndex(0)
                    }
                    .padding(.horizontal, 16)
                }
                .zIndex(1)
              
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Receive amount")
                                .font(.app(size: 15))
                                .foregroundColor(Color.TextSecondary)
                            Spacer()
                            Text("\(formatSmartAmount(receiveAmount)) \(asset.symbol)")
                                .font(.app(size: 15, weight: .bold))
                                .foregroundColor(Color.TextPrimary)
                        }
                       
                        HStack {
                            Text("Network fee")
                                .font(.app(size: 15))
                                .foregroundColor(Color.TextSecondary)
                            Spacer()
                            Text(formatFee(networkFeeUSD))
                                 .font(.app(size: 15, weight: .bold))
                                 .foregroundColor(Color.TextPrimary)
                        }
                    }
                   
                    Button(action: {
                        print("Withdraw Tapped")
                    }) {
                        Text("Withdraw")
                            .font(.app(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.FluxorPurple)
                            .cornerRadius(16)
                    }
                    .padding(.bottom, 40)
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(Color.bg)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if selectedNetwork == nil { selectedNetwork = asset.networks.first }
        }
    }
}

struct ConvertView: View {
    @Environment(\.dismiss) var dismiss
    let assets: [WalletAsset]
   
    @State private var sourceAsset: WalletAsset
    @State private var targetAsset: WalletAsset
    @State private var inputAmount: String = ""
    @State private var selectedChainId: Int = 1
    
    // Helpers
    var activeNetwork: CryptoNetwork? {
        sourceAsset.networks.first(where: { $0.id == selectedChainId }) ?? sourceAsset.networks.first
    }
    
    var targetNetwork: CryptoNetwork? {
        targetAsset.networks.first
    }
    
    var TotalCostUSD: Double {
            guard let network = activeNetwork else { return 0.0 }
            return FeeEstimator.getEstimatedNetworkFeeUSD(chainId: network.chainId)
    }
    
    init(assets: [WalletAsset]) {
        self.assets = assets
        _sourceAsset = State(initialValue: assets.first(where: { $0.symbol == "USDC" }) ?? assets[0])
        _targetAsset = State(initialValue: assets.first(where: { $0.symbol == "USDT" }) ?? assets.first(where: { $0.symbol == "ETH" }) ?? assets[1])
    }

    // ... (Your existing calculation logic remains here) ...

    var outputAmount: String {
        let input = cleanInputAmount
        guard input > 0 else { return "0.00" }
        let sourceRate = sourceAsset.amount > 0 ? sourceAsset.value / sourceAsset.amount : 0
        let targetRate = targetAsset.amount > 0 ? targetAsset.value / targetAsset.amount : 0
        
        guard targetRate > 0 else { return "0" }
        
        let result = input * (sourceRate / targetRate)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        formatter.usesGroupingSeparator = false
        formatter.locale = Locale(identifier: "en_US")
        
        return formatter.string(from: NSNumber(value: result)) ?? "\(result)"
    }
    
    var cleanInputAmount: Double {
        let cleanString = inputAmount.replacingOccurrences(of: ",", with: ".")
        return Double(cleanString) ?? 0.0
    }
    
    var fee: String { return "≈$0.21" }
    
    private func getFontSize(for text: String) -> CGFloat {
        let count = text.count
        if count < 9 { return 36 }
        else if count < 13 { return 28 }
        else if count < 17 { return 22 }
        else { return 18 }
    }
    
    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            
            VStack(spacing: -2) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left").font(.system(size: 20, weight: .medium)).foregroundColor(.TextPrimary)
                    }
                    Spacer()
                    Text("Convert").font(.app(size: 20, weight: .semibold)).foregroundColor(.TextPrimary)
                    Spacer()
                    Image(systemName: "arrow.left").opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 25)
                
                // Cards Container
                ZStack {
                    VStack(spacing: 6) {
                        // Source Card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("From").font(.app(size: 15, weight: .medium)).foregroundColor(.TextSecondary)
                                Spacer()
                            }
                            .padding(.top, -3)
                            
                            HStack(alignment: .center) {
                                StrictDecimalField(
                                    text: $inputAmount,
                                    placeholder: "0.00",
                                    uiFont: UIFont(name: "Inter-Medium", size: getFontSize(for: inputAmount)) ?? .systemFont(ofSize: getFontSize(for: inputAmount), weight: .medium),
                                    color: UIColor(Color.TextPrimary),
                                    maxAmount: sourceAsset.amount
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 40)
                                
                                HStack(spacing: 8) {
                                    ConvertTokenIcon(icon: sourceAsset.icon)
                                    Text(sourceAsset.symbol).font(.app(size: 20, weight: .semibold)).foregroundColor(.TextPrimary)
                                }
                                .padding(.leading, 6).padding(.trailing, 12).padding(.vertical, 8)
                                .background(Color.white.opacity(0.08)).cornerRadius(24)
                            }
                            .padding(.bottom, 5)
                            
                            HStack {
                                if let input = Double(inputAmount), input > 0 {
                                    let val = input * (sourceAsset.value / sourceAsset.amount)
                                    Text("$\(formatSmartValue(val))").font(.app(size: 14)).foregroundColor(.TextSecondary)
                                } else {
                                    Text("$0.00").font(.app(size: 14)).foregroundColor(.TextSecondary)
                                }
                                
                                Spacer()
            
                                HStack(spacing: 4) {
                                    Image(systemName: "wallet.bifold")
                                        .font(.system(size: 13))
                                    Text("\(formatSmartAmount(sourceAsset.amount)) \(sourceAsset.symbol)")
                                        .font(.app(size: 14, weight: .medium))
                                }
                                .foregroundColor(.TextSecondary)
                               
                                Button(action: {
                                    let formatted = formatSmartAmount(sourceAsset.amount)
                                    inputAmount = formatted.replacingOccurrences(of: ",", with: "")
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }) {
                                    Text("Max")
                                        .font(.app(size: 14, weight: .semibold))
                                        .foregroundColor(.TextPrimary)
                                }
                                .padding(.leading, 0)
                            }
                        }
                        .padding(20).background(Color.SwapCardBackground).cornerRadius(20)
                        
                        // Target Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("To").font(.app(size: 15, weight: .medium)).foregroundColor(.TextSecondary)
                                Spacer()
                            }
                            
                            HStack(alignment: .center) {
                                Text(outputAmount)
                                    .font(.system(size: getFontSize(for: outputAmount), weight: .medium))
                                    .foregroundColor((outputAmount == "0" || outputAmount == "0.00") ? .TextSecondary : .TextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 8) {
                                    ConvertTokenIcon(icon: targetAsset.icon)
                                    Text(targetAsset.symbol)
                                        .font(.app(size: 20, weight: .semibold))
                                        .foregroundColor(.TextPrimary)
                                }
                                .padding(.leading, 6).padding(.trailing, 12).padding(.vertical, 8)
                                .background(Color.white.opacity(0.08)).cornerRadius(24)
                            }
                            
                            HStack {
                                if let output = Double(outputAmount), output > 0 {
                                    let val = output * (targetAsset.value / targetAsset.amount)
                                    Text("$\(formatSmartValue(val))").font(.app(size: 14)).foregroundColor(.TextSecondary)
                                } else {
                                    Text("$0.00").font(.app(size: 14)).foregroundColor(.TextSecondary)
                                }
                                Spacer()
                            }
                        }
                        .padding(20).background(Color.SwapCardBackground).cornerRadius(20)
                    }
                    
                    // Floating Swap Button
                    Button(action: {
                        let temp = sourceAsset; sourceAsset = targetAsset; targetAsset = temp
                        inputAmount = ""
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        ZStack {
                            Circle().fill(Color.bg).frame(width: 48, height: 48)
                            Circle().fill(Color.SwapCardBackground).frame(width: 40, height: 40).overlay(Circle().stroke(Color.bg, lineWidth: 4))
                            Image(systemName: "arrow.down").font(.system(size: 18, weight: .bold)).foregroundColor(.TextPrimary)
                        }
                    }.offset(y: 4)
                }
                .padding(.horizontal, 16)
                
                HStack {
                        Text("Total Cost")
                            .font(.app(size: 16, weight: .medium))
                            .foregroundColor(.TextSecondary)
                        Spacer()
                        Text(formatFee(TotalCostUSD))
                            .font(.app(size: 16, weight: .medium))
                            .foregroundColor(.TextPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
            
                Button(action: { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }) {
                    Text("Convert")
                        .font(.app(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.FluxorPurple)
                        .cornerRadius(20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        .onAppear { if selectedChainId == 0, let first = sourceAsset.networks.first { selectedChainId = first.id } }
    }
}

// MARK: - Helper: Token Icon (No Badge)
struct ConvertTokenIcon: View {
    let icon: String
    
    var body: some View {
        Image(icon)
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .clipShape(Circle())
    }
}

#Preview {
    Wallet()
}
