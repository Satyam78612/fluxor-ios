//
//  Trade.swift
//  Fluxor
//
//  Created by Satyam Singh on 22/11/25.
//

import SwiftUI

fileprivate enum Layout {
    static let horizontalPadding: CGFloat = 13
    static let verticalPadding: CGFloat = 12
    static let columnSpacing: CGFloat = 8
    static let cornerRadius: CGFloat = 10
    static let orderbookRatio: CGFloat = 0.38
    static let orderbookMin: CGFloat = 120
    static let orderbookMax: CGFloat = 420
    static let leftColumnMin: CGFloat = 180
    static let orderbookHeight: CGFloat? = nil
    static let orderbookMaxHeight: CGFloat = 355
    static let headerIconSize: CGFloat = 35
    static let pillHeight: CGFloat = 45
    static let sectionInset: CGFloat = 7
    static let formSpacing: CGFloat = 11
}

fileprivate extension Color {
    static let bg = Color("AppBackground")
    static let card = Color("SwapCardBackground")
    static let TextPrimary = Color("TextPrimary")
    static let TextSecondary = Color("TextSecondary")
    static let Divider = Color("DividerColor")
    static let green = Color("AppGreen")
    static let red = Color("AppRed")
    static let HistoryCard = Color("HistoryCard")
}

struct TradeStrictDecimalField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var uiFont: UIFont?
    var color: UIColor
    var maxAmount: Double? = nil
    var alignment: NSTextAlignment = .center
    var isEnabled: Bool = true
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .decimalPad
        textField.placeholder = placeholder
        textField.font = uiFont ?? .systemFont(ofSize: 17)
        textField.textColor = color
        textField.textAlignment = alignment
        
        // Add placeholder color styling
        if let placeholder = textField.placeholder {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(named: "TextSecondary") ?? UIColor.gray
            ]
            textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attributes)
        }
        
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.textColor = color
        uiView.isEnabled = isEnabled
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: TradeStrictDecimalField
        
        init(_ parent: TradeStrictDecimalField) {
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
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                }
            }
            
            return true
        }
    }
}

struct AssetItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let symbol: String
    let price: String
    let change: String
    let isPositive: Bool
    let balanceValue: String
    let balanceAmount: String
    let iconName: String

    static func == (lhs: AssetItem, rhs: AssetItem) -> Bool {
        return lhs.id == rhs.id
    }
}

struct NetworkTxInfo: Identifiable, Hashable {
    let id = UUID()
    let type: String
    let networkName: String
    let txHash: String
}

struct HistoryItem: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let type: String
    let time: String
    let price: String
    let buyAmount: String
    let sellAmount: String
    let gasFee: String
    let appFee: String
    let status: String

    let targetTx: NetworkTxInfo?
    let settlementTx: NetworkTxInfo?
    let sourceTxs: [NetworkTxInfo]

    var iconSymbol: String {
        let normalized = symbol.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "btc": return "btc"
        case "eth": return "eth"
        case "sol": return "sol"
        case "usdc": return "usdc"
        case "aave": return "aave"
        case "parti": return "parti"
        case "eigen": return "eigen"
        default: return "\(normalized)"
        }
    }
}

struct Trade: View {
    enum TradeSide { case buy, sell }
    
    private enum PortfolioSortField { case none, balance }
    private enum PortfolioSortDirection { case asc, desc }
    
    @ObservedObject var marketVM: MarketViewModel
    @StateObject private var walletVM = WalletViewModel()
    @State private var showSlippageSettings = false
    @State private var slippage: Double? = nil
    @State private var customSlippage: String = ""
    @State private var solanaTxMode: String = "Auto"
    @State private var currentSide: TradeSide = .buy
    @State private var selectedHistoryItem: HistoryItem?
    @State private var amountInput: String = ""
    @State private var totalInput: String = ""
    @State private var sliderValue: Double = 0
    @State private var isUserTyping: Bool = false
    @State private var showingInsufficientFundsAlert: Bool = false
    @State private var selectedTabIndex: Int = 0
    @State private var selectedAssetTab: String = "Assets"
    @State private var showTokenSelector: Bool = false
    @State private var selectedAsset: AssetItem = AssetItem(
        name: "Bitcoin",
        symbol: "BTC",
        price: "$91,700",
        change: "+4.02%",
        isPositive: true,
        balanceValue: "$250",
        balanceAmount: "0.0034",
        iconName: "btc"
    )
    
    private let availableUSD: Double = 22000
    
    var themeColor: Color { currentSide == .buy ? .green : .red }
    
    private var tokenPrice: Double {
        Double(selectedAsset.price.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0
    }
    
    private var availableTokenBalance: Double {
        Double(selectedAsset.balanceAmount.replacingOccurrences(of: ",", with: "")) ?? 0
    }
    
    private var isOverBalance: Bool {
        if currentSide == .buy {
            guard let usd = Double(totalInput) else { return false }
            return usd > availableUSD
        } else {
            guard let amt = Double(amountInput) else { return false }
            return amt > availableTokenBalance
        }
    }
    
    private var isTradeValid: Bool {
        if isOverBalance { return false }
        
        if currentSide == .buy {
            guard let usd = Double(totalInput) else { return false }
            return usd >= 1.0
        } else {
            guard let amt = Double(amountInput) else { return false }
            let usdValue = amt * tokenPrice
            return usdValue >= 1.0
        }
    }
    
    private func simulateBackendQuote(inputAmount: Double, side: TradeSide) -> Double {
        // No fee/spread simulation anymore. Exact math.
        
        if side == .buy {
            // Input is USD -> Return BTC
            return inputAmount / max(0.000001, tokenPrice)
        } else {
            // Input is BTC -> Return USD
            return inputAmount * tokenPrice
        }
    }
    
    @State private var portfolioSortField: PortfolioSortField = .none
    @State private var portfolioSortDirection: PortfolioSortDirection = .desc
        
        private var displayedWalletPortfolio: [WalletAsset] {
            var assets = walletVM.assets
            
            switch portfolioSortField {
            case .none:
                break
            case .balance:
                assets.sort {
                    if portfolioSortDirection == .asc {
                        return $0.value < $1.value
                    } else {
                        return $0.value > $1.value
                    }
                }
            }
            return assets
        }
    
    private let historyData: [HistoryItem] = [
        HistoryItem(
            symbol: "AAVE",
            type: "Buy",
            time: "14 Sep 2025, 11:57 AM",
            price: "$0.12",
            buyAmount: "+1.2 AAVE",
            sellAmount: "-$150 USD",
            gasFee: "$0.10",
            appFee: "$0.03",
            status: "Success",
            
            targetTx: NetworkTxInfo(type: "Target", networkName: "Base", txHash: "0x92...5ab8"),
            settlementTx: NetworkTxInfo(type: "Settlement", networkName: "Particle Chain", txHash: "0x31...5460"),
            
            sourceTxs: [
                NetworkTxInfo(type: "From", networkName: "BNB Chain", txHash: "0x31...5460"),
                NetworkTxInfo(type: "From", networkName: "Arbitrum", txHash: "0xd8...4578")
            ]
        ),
        HistoryItem(
            symbol: "EIGEN",
            type: "Sell",
            time: "12 Aug 2025, 10:49 PM",
            price: "$0.50",
            buyAmount: "+$150 USD",
            sellAmount: "-300 EIGEN",
            gasFee: "$0.03",
            appFee: "$0.30",
            status: "Success",
            
            targetTx: NetworkTxInfo(type: "Target", networkName: "Base", txHash: "0x92...5ab8"),
            settlementTx: NetworkTxInfo(type: "Settlement", networkName: "Particle Chain", txHash: "0x31...5460"),
            
            sourceTxs: [
                NetworkTxInfo(type: "From", networkName: "BNB Chain", txHash: "0x31...5460"),
                NetworkTxInfo(type: "From", networkName: "Arbitrum", txHash: "0xd8...4578"),
                NetworkTxInfo(type: "From", networkName: "Solana", txHash: "0xd8...4578"),
                NetworkTxInfo(type: "From", networkName: "Optimism", txHash: "0xd8...4578"),
                NetworkTxInfo(type: "From", networkName: "Polygon", txHash: "0xd8...4578")
            ]
        ),
        HistoryItem(
            symbol: "BTC",
            type: "Buy",
            time: "14 Aug 2025, 10:49 AM",
            price: "$90,000",
            buyAmount: "+0.1 BTC",
            sellAmount: "-$9000",
            gasFee: "$1.0",
            appFee: "$0.5",
            status: "Success",
            
            targetTx: NetworkTxInfo(type: "Target", networkName: "Arbitrum", txHash: "0x92...5ab8"),
            settlementTx: NetworkTxInfo(type: "Settlement", networkName: "Particle Chain", txHash: "0x31...5460"),
            
            sourceTxs: [
                NetworkTxInfo(type: "From", networkName: "BNB Chain", txHash: "0x31...5460"),
                NetworkTxInfo(type: "From", networkName: "Arbitrum", txHash: "0xd8...4578"),
                NetworkTxInfo(type: "From", networkName: "Solana", txHash: "0xd8...4578")
            ]
        ),
        HistoryItem(
            symbol: "ETH",
            type: "Sell",
            time: "12 Sep 2025, 11:40 PM",
            price: "$3,000",
            buyAmount: "+$3000",
            sellAmount: "-1 ETH",
            gasFee: "$0.5",
            appFee: "$0.5",
            status: "Success",
            
            targetTx: NetworkTxInfo(type: "Target", networkName: "Solana", txHash: "0x92...5ab8"),
            settlementTx: NetworkTxInfo(type: "Settlement", networkName: "Particle Chain", txHash: "0x31...5460"),
            
            sourceTxs: [
                NetworkTxInfo(type: "From", networkName: "BNB Chain", txHash: "0x31...5460"),
                NetworkTxInfo(type: "From", networkName: "Arbitrum", txHash: "0xd8...4578"),
                NetworkTxInfo(type: "From", networkName: "Solana", txHash: "0xd8...4578")
            ]
        )
    ]
    
    private var customAlertView: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showingInsufficientFundsAlert = false }
                }
            
            VStack(spacing: 0) {
                Text("Insufficient Balance")
                    .font(.app(size: 17, weight: .semibold))
                    .foregroundColor(.TextPrimary)
                    .padding(.top, 20)
                
                Text(currentSide == .buy ?
                     "Your Available Balance is $\(String(format: "%.2f", availableUSD))." :
                     "Your Available Balance is \(selectedAsset.balanceAmount) \(selectedAsset.symbol).")
                    .font(.app(size: 13, weight: .regular))
                    .foregroundColor(.TextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.top, 8)
                    .padding(.bottom, 15)
                    .padding(.horizontal, 15)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                Button(action: {
                    withAnimation { showingInsufficientFundsAlert = false }
                }) {
                    Text("OK")
                        .font(.app(size: 17, weight: .bold))
                        .foregroundColor(.TextPrimary)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
            }
            .frame(width: 270)
            .background(Color.bg)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
        .zIndex(100)
        .transition(.opacity)
    }
    
    var body: some View {
        GeometryReader { fullGeo in
            ZStack(alignment: .top) {
                Color.bg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, Layout.horizontalPadding)
                        .padding(.top, 5)
                        .background(Color.bg)
                        .zIndex(1)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            
                            GeometryReader { geo in
                                let totalW = geo.size.width
                                let availableH = geo.size.height
                                let contentHeight = availableH
                                
                                let (leftWidth, orderbookWidth): (CGFloat, CGFloat) = {
                                    let rawOrderbook = totalW * Layout.orderbookRatio
                                    var obW = max(Layout.orderbookMin, min(rawOrderbook, Layout.orderbookMax))
                                    var lW = max(Layout.leftColumnMin, totalW - obW - Layout.columnSpacing - (Layout.horizontalPadding * 2))
                                    
                                    if lW + obW + Layout.columnSpacing + (Layout.horizontalPadding * 2) > totalW {
                                        let usable = max(0, totalW - Layout.columnSpacing - (Layout.horizontalPadding * 2))
                                        lW = usable * 0.63
                                        obW = usable - lW
                                    }
                                    obW = min(max(obW, Layout.orderbookMin), Layout.orderbookMax)
                                    lW  = max(lW, Layout.leftColumnMin)
                                    return (lW, obW)
                                }()
                                
                                HStack(alignment: .top, spacing: Layout.columnSpacing) {
                                    leftForm
                                        .frame(width: leftWidth, height: contentHeight, alignment: .top)
                                    
                                    OrderbookView(themeColor: themeColor, tokenPrice: tokenPrice)
                                        .frame(width: orderbookWidth, height: contentHeight, alignment: .top)
                                }
                                .padding(.horizontal, Layout.horizontalPadding)
                                .padding(.top, Layout.sectionInset)
                            }
                            .frame(height: Layout.orderbookMaxHeight)
                            
                            VStack(spacing: 0) {
                                HStack(spacing: 8) {
                                    tabButton(title: "Portfolio", index: 0)
                                    tabButton(title: "History", index: 1)
                                    Spacer()
                                }
                                .padding(.top, 12)
                                .padding(.horizontal, Layout.horizontalPadding)
                                
                                Divider().background(Color.gray.opacity(0.3))
                                    .padding(.top, -2)
                                
                                if selectedTabIndex == 0 {
                                    VStack(spacing: -2) {
                                        HStack {
                                            Text("Name")
                                                .font(.app(size: 13))
                                                .foregroundColor(.TextSecondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.leading, 7)
                                            
                                            HStack(spacing: 0) {
                                                Text("Balance")
                                                    .font(.app(size: 13))
                                                    .foregroundColor(.TextSecondary)
                                                
                                                VStack(spacing: -10) {
                                                    Button(action: {
                                                        withAnimation {
                                                            portfolioSortField = .balance
                                                            portfolioSortDirection = .asc
                                                        }
                                                    }) {
                                                        Image(systemName: "triangle.fill")
                                                            .font(.system(size: 5))
                                                            .foregroundColor(
                                                                (portfolioSortField == .balance && portfolioSortDirection == .asc)
                                                                ? Color.TextPrimary
                                                                : Color.TextSecondary.opacity(0.6)
                                                            )
                                                    }
                                                    .buttonStyle(.plain)
                                                    .frame(width: 28, height: 18)
                                                    
                                                    Button(action: {
                                                        withAnimation {
                                                            portfolioSortField = .balance
                                                            portfolioSortDirection = .desc
                                                        }
                                                    }) {
                                                        Image(systemName: "triangle.fill")
                                                            .font(.system(size: 5))
                                                            .rotationEffect(.degrees(180))
                                                            .foregroundColor(
                                                                (portfolioSortField == .balance && portfolioSortDirection == .desc)
                                                                ? Color.TextPrimary
                                                                : Color.TextSecondary.opacity(0.6)
                                                            )
                                                    }
                                                    .buttonStyle(.plain)
                                                    .frame(width: 28, height: 18)
                                                }
                                                .frame(width: 22, alignment: .trailing)
                                            }
                                            .frame(width: 75, alignment: .trailing)
                                            .padding(.trailing, -8)
                                        }
                                        .padding(.horizontal, Layout.horizontalPadding)
                                        .padding(.top, 6)
                                        
                                        VStack(spacing: 0) {
                                            ForEach(displayedWalletPortfolio) { asset in
                                                
                                                let priceValue = asset.amount > 0 ? (asset.value / asset.amount) : 0.0
                                                let startValue = asset.value - asset.dayChangeUSD
                                                let percentChange = startValue > 0 ? (asset.dayChangeUSD / startValue) * 100 : 0.0
                                                let item = AssetItem(
                                                    name: asset.name,
                                                    symbol: asset.symbol,
                                                    price: "$\(String(format: "%.2f", priceValue))",
                                                    change: String(format: "%@%.2f%%", percentChange >= 0 ? "+" : "", percentChange),
                                                    isPositive: percentChange >= 0,
                                                    balanceValue: "$\(formatSmartValue(asset.value))",
                                                    balanceAmount: formatSmartAmount(asset.amount),
                                                    iconName: asset.icon
                                                )
                                                
                                                PortfolioRowView(asset: item)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        withAnimation {
                                                            self.selectedAsset = item
                                                            self.amountInput = ""
                                                            self.totalInput = ""
                                                            self.sliderValue = 0
                                                        }
                                                    }
                                            }
                                        }
                                        .padding(.bottom, 40)
                                    }
                                    
                                } else {
                                    VStack(spacing: 12) {
                                        if historyData.isEmpty {
                                            Spacer().frame(height: 50)
                                            
                                            Text("No History")
                                                .font(.app(size: 16))
                                                .foregroundColor(.TextSecondary)
                                            
                                        } else {
                                            ForEach(historyData) { item in
                                                Button(action: { selectedHistoryItem = item }) {
                                                    HistoryCard(item: item)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                    .padding(.top, 14)
                                    .padding(.horizontal, Layout.horizontalPadding)
                                    .padding(.bottom, 40)
                                }
                            }
                        }
                    }
                }
                if showingInsufficientFundsAlert {
                    customAlertView
                }
                
                if showSlippageSettings {
                    SlippageSettingsView(
                        slippage: $slippage,
                        customSlippage: $customSlippage,
                        solanaTxMode: $solanaTxMode,
                        isPresented: $showSlippageSettings
                        
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(200)
                    .transition(.opacity)
                    
                }
            }
            
            .onChange(of: sliderValue) { _old, newVal in
                if !isUserTyping {
                    let pct = max(0.0, min(100.0, newVal)) / 100.0
                    
                    if currentSide == .buy {
                        let usdVal = pct * availableUSD
                        
                        // Ask "Backend": How much BTC do I get for this USD?
                        let estimatedBTC = simulateBackendQuote(inputAmount: usdVal, side: .buy)
                        
                        totalInput = formatPrice(usdVal)
                        amountInput = formatAmount(estimatedBTC)
                        
                    } else {
                        let tokenAmt = pct * availableTokenBalance
                        
                        // Ask "Backend": How much USD do I get for this BTC?
                        let estimatedUSD = simulateBackendQuote(inputAmount: tokenAmt, side: .sell)
                        
                        amountInput = formatAmount(tokenAmt)
                        totalInput = formatPrice(estimatedUSD)
                    }
                }
            }
            
            .onChange(of: totalInput) { _old, newVal in
                guard currentSide == .buy else { return }
                isUserTyping = true
                
                if let usdVal = Double(newVal) {
                    // Cap USD at available balance
                    let effectiveUSD = min(usdVal, availableUSD)
                    
                    // Call Backend for BTC Amount (Exact Math)
                    let estimatedBTC = simulateBackendQuote(inputAmount: effectiveUSD, side: .buy)
                    amountInput = formatAmount(estimatedBTC)
                    
                    let newSliderVal = (usdVal / availableUSD) * 100
                    if abs(sliderValue - newSliderVal) > 0.5 {
                        sliderValue = min(newSliderVal, 100)
                    }
                } else {
                    amountInput = "0.0000"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isUserTyping = false }
            }
            
            .onChange(of: amountInput) { _old, newVal in
                guard currentSide == .sell else { return }
                isUserTyping = true
                
                if let amtVal = Double(newVal) {
                    // Cap Amount at available balance
                    let effectiveAmt = min(amtVal, availableTokenBalance)
                    
                    // Call Backend for USD Total (Exact Math)
                    let estimatedUSD = simulateBackendQuote(inputAmount: effectiveAmt, side: .sell)
                    totalInput = formatPrice(estimatedUSD)
                    
                    let newSliderVal = (amtVal / availableTokenBalance) * 100
                    if abs(sliderValue - newSliderVal) > 0.5 {
                        sliderValue = min(newSliderVal, 100)
                    }
                } else {
                    totalInput = "0.00"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isUserTyping = false }
            }
            .sheet(item: $selectedHistoryItem) { item in TransactionDetail(item: item) }
            .sheet(isPresented: $showTokenSelector) { TokenSelectionView(selectedAsset: $selectedAsset, marketVM: marketVM) }
        }
        .task {
            if marketVM.allTokens.isEmpty {
                await marketVM.loadData()
            }
        }
    }
    
    private func formatWithCommas(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
                
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
    
    private var leftForm: some View {
        VStack(alignment: .leading, spacing: Layout.formSpacing) {
            HStack(spacing: 0) {
                segmentButton(title: "Buy", side: .buy)
                segmentButton(title: "Sell", side: .sell)
            }
            .background(Color.card)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
            
            HStack {
                Spacer()
                Text("Market")
                    .font(.app(size: 16, weight: .semibold))
                    .foregroundColor(.TextPrimary)
                Spacer()
            }
            .frame(height: Layout.pillHeight)
            .background(Color.card)
            .cornerRadius(Layout.cornerRadius)
            
            if currentSide == .buy {
                amountView(isEditable: false)
                sliderView
                totalView(isEditable: true)
            } else {
                totalView(isEditable: false)
                sliderView
                amountView(isEditable: true)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("Avbl")
                        .foregroundColor(.TextSecondary)
                    Spacer()
                    if currentSide == .buy {
                        Text("\(formatWithCommas(availableUSD)) USD")
                            .foregroundColor(.TextPrimary)
                    } else {
                        Text("\(selectedAsset.balanceAmount) \(selectedAsset.symbol)")
                            .foregroundColor(.TextPrimary)
                    }
                }
                HStack {
                    Text("Min received")
                        .foregroundColor(.TextSecondary)
                    Spacer()
                    if currentSide == .buy {
                        let btcAmount = Double(amountInput) ?? 0.0
                        Text("\(formatAmount(btcAmount)) \(selectedAsset.symbol)")
                            .foregroundColor(.TextPrimary)
                    } else {
                        let usdAmount = Double(totalInput) ?? 0.0
                        Text("\(formatPrice(usdAmount)) USD")
                            .foregroundColor(.TextPrimary)
                    }
                }
                HStack {
                    Text("Gas cost")
                        .foregroundColor(.TextSecondary)
                    Spacer()
                    Text("0.10 USD")
                        .foregroundColor(.TextPrimary)
                }
            }
            .font(.app(size: 14, weight: .medium))
            .padding(.vertical, 0)
            .padding(.horizontal, 3)
            
            Button(action: {
                if isOverBalance {
                    withAnimation { showingInsufficientFundsAlert = true }
                } else if isTradeValid {
                    print("Trade Executed")
                }
            }) {
                Text(currentSide == .buy ? "Buy \(selectedAsset.symbol)" : "Sell \(selectedAsset.symbol)")
                    .font(.app(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(isOverBalance ? Color.gray : themeColor)
                    .cornerRadius(10)
            }
            .disabled(!isTradeValid && !isOverBalance)
            .padding(.top, 0)
            
            Spacer()
        }
        .padding(.vertical, 2)
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    private func amountView(isEditable: Bool) -> some View {
        HStack {
            Spacer()
            
            if isEditable {
                TradeStrictDecimalField(
                    text: $amountInput,
                    placeholder: "Amount (\(selectedAsset.symbol))",
                    uiFont: UIFont(name: "AppFont-Regular", size: 17),
                    color: UIColor(Color.TextPrimary),
                    maxAmount: nil,
                    alignment: .center,
                    isEnabled: isEditable
                )
                .frame(height: 24)
            } else {
                Text(amountInput.isEmpty ? "Amount (\(selectedAsset.symbol))" : amountInput)
                    .font(.app(size: 17, weight: .regular))
                    .foregroundColor(amountInput.isEmpty ? .TextSecondary : .TextPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Spacer()
        }
        .frame(height: Layout.pillHeight)
        .background(Color.card)
        .cornerRadius(Layout.cornerRadius)
        .overlay((currentSide == .buy) ? Divider().opacity(0) : nil, alignment: .bottom)
    }
    
    private func totalView(isEditable: Bool) -> some View {
        HStack {
            Spacer()
            
            if isEditable {
                TradeStrictDecimalField(
                    text: $totalInput,
                    placeholder: "Total (USD)",
                    uiFont: UIFont(name: "AppFont-Regular", size: 16),
                    color: UIColor(Color.TextPrimary),
                    maxAmount: nil,
                    alignment: .center,
                    isEnabled: isEditable
                )
                .frame(height: 24)
            } else {
                Text(totalInput.isEmpty ? "Total (USD)" : totalInput)
                    .font(.app(size: 16, weight: .regular))
                    .foregroundColor(totalInput.isEmpty ? .TextSecondary : .TextPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Spacer()
        }
        .frame(height: Layout.pillHeight)
        .background(Color.card)
        .cornerRadius(Layout.cornerRadius)
        .overlay((currentSide == .sell) ? Divider().opacity(0) : nil, alignment: .bottom)
    }
        
    private var sliderView: some View {
        ThinSlider(value: $sliderValue, accent: themeColor)
            .frame(height: 4)
            .padding(.horizontal, 5)
            .padding(.vertical, 0)
    }
    
    private func segmentButton(title: String, side: TradeSide) -> some View {
        Button { withAnimation {
            currentSide = side
            amountInput = ""
            totalInput = ""
            sliderValue = 0
        } } label: {
            Text(title).font(.app(size: 15, weight: .semibold))
                .foregroundColor(currentSide == side ? .white : .TextSecondary)
                .frame(maxWidth: .infinity).padding(.vertical, 9)
                .background(currentSide == side ? themeColor : Color.clear)
                .cornerRadius(10)
        }.buttonStyle(PlainButtonStyle())
    }
    
    private func formatAmount(_ v: Double) -> String {
        if v >= 1 { return String(format: "%.4f", v) }
        return String(format: "%.6f", v)
    }
    private func formatPrice(_ v: Double) -> String {
        return String(format: "%.2f", v)
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: { selectedAssetTab = title; selectedTabIndex = index }) {
            VStack(spacing: 6.5) {
                Text(title).font(.app(size: 18, weight: .semibold))
                    .foregroundColor(selectedTabIndex == index ? .TextPrimary : .TextSecondary)
                
                Rectangle().frame(height: 2).frame(width: 15)
                    .foregroundColor(selectedTabIndex == index ? .TextPrimary : .clear).cornerRadius(100)
                }
                .frame(width: 80).background(Color.bg.opacity(0.01))
                .padding(.top, 3)
            
        }.buttonStyle(PlainButtonStyle())
    }
    
    private var header: some View {
        HStack {
            Button(action: { showTokenSelector = true }) {
                HStack(spacing: 6) {
                    Image(selectedAsset.iconName).resizable().scaledToFit().frame(width: 35, height: 35).clipShape(Circle())
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 6) {
                            Text("\(selectedAsset.symbol)/USD").font(.app(size: 18, weight: .semibold)).foregroundColor(.TextPrimary)
                            Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold)).foregroundColor(.TextSecondary)
                        }
                        Text(selectedAsset.change).font(.app(size: 12, weight: .regular)).foregroundColor(selectedAsset.isPositive ? .green : .red)
                    }
                }
            }.buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            HStack(spacing: 1) {
                HStack(spacing: 2) {
                    
                    Button(action: { showSlippageSettings = true }) {
                        Image("Slippage")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.TextPrimary)
                            .padding(8)
                    }.buttonStyle(PlainButtonStyle())
                }
                
                Button(action: {}) {
                    
                    Image("Candle")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.TextPrimary)
                        .padding(8)
                }.buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(900))
                        .padding(8)
                        .foregroundColor(.TextPrimary)
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct TokenSelectionView: View {
    @Binding var selectedAsset: AssetItem
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: MarketTab = .all
    @State private var sortField: SortField = .none
    @State private var sortDirection: SortDirection = .desc
    @State private var searchText: String = ""
    @ObservedObject var marketVM: MarketViewModel

    private var tokens: [Token] { marketVM.allTokens }
    
    private var filteredTokens: [Token] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var list: [Token]
        
        if !needle.isEmpty {
            list = tokens.filter {
                $0.name.lowercased().contains(needle) ||
                $0.symbol.lowercased().contains(needle) ||
                $0.contractAddress.lowercased().contains(needle)
            }
            
            if let apiToken = marketVM.searchedToken {
                if !list.contains(where: { $0.id == apiToken.id }) {
                    list.insert(apiToken, at: 0)
                }
            }
        } else {
            switch selectedTab {
            case .favorites: list = marketVM.favoriteTokens
            case .all: list = tokens
            case .trending: list = marketVM.trending
            case .gainers: list = marketVM.gainers
            case .losers: list = marketVM.losers
            default: list = tokens
            }
        }

        switch sortField {
        case .price:
            list.sort { a, b in sortDirection == .asc ? ((a.price ?? 0) < (b.price ?? 0)) : ((a.price ?? 0) > (b.price ?? 0)) }
        case .change:
            list.sort { a, b in sortDirection == .asc ? ((a.changePercent ?? 0) < (b.changePercent ?? 0)) : ((a.changePercent ?? 0) > (b.changePercent ?? 0)) }
        case .none: break
        }
        return list
    }

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                
                HStack {
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.TextSecondary)
                    }
                }
                .padding(.top, 20)
                
                AdaptiveSearchBar(searchText: $searchText, marketVM: marketVM)
                    .padding(.bottom, 1)
                    .onChange(of: searchText) { oldValue, newValue in
                        if newValue.isEmpty {
                            marketVM.searchedToken = nil
                        }
                    }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(MarketTab.allCases) { tab in
                            Button {
                                selectedTab = tab
                            } label: {
                                VStack(spacing: 2) {
                                    Text(tab.rawValue)
                                        .font(.app(size: 17, weight: tab == selectedTab ? .semibold : .semibold))
                                        .foregroundColor(tab == selectedTab ? Color.TextPrimary : Color.TextSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.top, -6)
                    .padding(.horizontal, -11)
                
                HStack(spacing: 7) {
                    Text("Name")
                        .font(.app(size: 13, weight: .semibold))
                        .foregroundColor(Color.TextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 0.6)
                    
                    HStack(spacing: 1) {
                        Text("Price")
                            .font(.app(size: 13, weight: .regular))
                            .foregroundColor(Color.TextSecondary)
                            .frame(width: 100, alignment: .trailing)
                        
                        SortButton(isActive: sortField == .price, direction: sortDirection) {
                            handleSortTap(field: .price)
                        }
                    }
                    .frame(width: 140, alignment: .trailing)
                    
                    HStack(spacing: 1) {
                        Text("24h %")
                            .font(.app(size: 13, weight: .regular))
                            .foregroundColor(Color.TextSecondary)
                            .frame(width: 92, alignment: .trailing)
                        
                        SortButton(isActive: sortField == .change, direction: sortDirection) {
                            handleSortTap(field: .change)
                        }
                    }
                    .frame(width: 88.5, alignment: .trailing)
                }
                .padding(.top, -5)
                .padding(.bottom, -5)
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        
                        if filteredTokens.isEmpty {
                            if marketVM.isLoading {
                                ProgressView()
                                    .padding(.top, 20)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                Text("No tokens found")
                                    .font(.app(size: 16))
                                    .foregroundColor(Color.TextSecondary)
                                    .padding(.top, 20)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        } else {
                            ForEach(filteredTokens) { token in
                                Button { selectAndDismiss(token) } label: {
                                    HStack(spacing: 12) {
                                        HStack(spacing: 8) {
                                            TokenIcon(token: token, size: 34)
                                            
                                            VStack(alignment: .leading, spacing: 2.5) {
                                                Text(token.name).font(.app(size: 17, weight: .semibold)).foregroundColor(Color.TextPrimary).lineLimit(1)
                                                
                                                Text(token.symbol).font(.app(size: 14, weight: .medium)).foregroundColor(Color.TextSecondary)
                                            }
                                        }
                                        Spacer()
                                        
                                            SmartPriceText(value: token.price ?? 0, fontSize: 16, weight: .semibold, color: .TextPrimary).padding(.trailing, 8)
                                        
                                        ChangeBadgeView(value: token.changePercent ?? 0)
                                    }.padding(.vertical, 7).contentShape(Rectangle())
                                }.buttonStyle(PlainButtonStyle())
                            }
                        }
                    }.padding(.top, 0)
                }
            }.padding(.horizontal, 11).padding(.bottom, 16)
        }
    }

    private func handleSortTap(field: SortField) {
        if sortField == field { sortDirection = (sortDirection == .desc) ? .asc : .desc }
        else { sortField = field; sortDirection = .desc }
    }
        
    private func selectAndDismiss(_ token: Token) {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = (token.price ?? 0) < 1 ? 6 : 2
        let priceStr = formatter.string(from: NSNumber(value: token.price ?? 0)) ?? "$0.00"
        
        let change = token.changePercent ?? 0
        let changeStr = String(format: "%@%.2f%%", change >= 0 ? "+" : "-", abs(change))
        
        let newItem = AssetItem(
            name: token.name,
            symbol: token.symbol,
            price: priceStr,
            change: changeStr,
            isPositive: change >= 0,
            balanceValue: "$0.00",
            balanceAmount: "0.00",
            iconName: token.logo
        )
        
        selectedAsset = newItem
        dismiss()
    }
}

struct OrderbookView: View {
    var themeColor: Color
    var tokenPrice: Double
    
    private let sidePadding: CGFloat = 4
    private let mixedOrders: [(String, String, Bool)] = [
        ("91,735.50", "0.4500", false), ("91,730.00", "0.0028", true), ("91,728.50", "0.1500", true),
        ("91,725.20", "0.0450", true), ("91,736.00", "0.2100", false), ("91,737.50", "0.0550", false),
        ("91,720.00", "1.0200", true), ("91,718.50", "0.0010", true), ("91,739.20", "0.5000", false),
        ("91,740.00", "0.1200", false), ("91,742.00", "0.1230", true)
    ]
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let availableWidth = width - (sidePadding * 1.5)
            let priceColW = availableWidth * 0.55
            let valueColW = availableWidth * 0.45
            
            VStack(spacing: 8) {
                SmartPriceText(value: tokenPrice, fontSize: 18, weight: .semibold, color: .TextPrimary)
                    .frame(maxWidth: .infinity).padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.card))
                    .padding(.horizontal, 2.8).padding(.top, 2)
            
                Divider().background(Color.Divider.opacity(0.25))
            
                HStack(spacing: 0) {
                    Text("Price ($)").font(.app(size: 11, weight: .semibold)).foregroundColor(.TextSecondary).frame(width: priceColW, alignment: .leading)
                    
                    Text("Amount").font(.app(size: 11, weight: .semibold)).foregroundColor(.TextSecondary).frame(width: valueColW, alignment: .trailing)
                }.padding(.horizontal, sidePadding).padding(.bottom, -8)
            
                VStack(spacing: -2.1) {
                    ForEach(mixedOrders.indices, id: \.self) { i in
                        let order = mixedOrders[i]
                        HStack(spacing: 0) {
                            Text(order.0).font(.app(size: 13, weight: .semibold)).foregroundColor(order.2 ? .green : .red).frame(width: priceColW, alignment: .leading).lineLimit(1)
                            Text(order.1).font(.app(size: 13, weight: .regular)).foregroundColor(.TextPrimary).frame(width: valueColW, alignment: .trailing).lineLimit(1)
                        }.padding(.horizontal, sidePadding).padding(.vertical, 5.8)
                    }
                    Spacer(minLength: 6)
                }
            }.background(Color.bg)
        }
    }
}

struct ThinSlider: View {
    @Binding var value: Double
    var accent: Color
    private let dots: [CGFloat] = [0.0, 0.25, 0.5, 0.75, 1.0]
    var body: some View {
        GeometryReader { g in
            let w = max(g.size.width, 1)
            let pct = CGFloat(min(max(value / 100, 0), 1))
            let knobX = pct * w
            let trackHeight: CGFloat = 4
            let dotSize: CGFloat = 5
            let knobSize: CGFloat = 9.2
            let hitWidth: CGFloat = max(44, dotSize * 3)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray.opacity(0.20)).frame(height: trackHeight)
                Capsule().fill(Color.gray.opacity(0.30)).frame(width: knobX, height: trackHeight)
                ForEach(dots.indices, id: \.self) { i in
                    let x = dots[i] * w
                    Button { withAnimation(.easeInOut) { value = Double(dots[i] * 100) } } label: {
                        Circle().fill(Color.gray.opacity(0.50)).frame(width: dotSize, height: dotSize)
                            .overlay(Circle().stroke((pct >= dots[i]) ? Color.gray.opacity(0.6) : Color.gray.opacity(0.50), lineWidth: 0.7).frame(width: dotSize, height: dotSize))
                            .frame(width: hitWidth, height: g.size.height)
                    }
                    .buttonStyle(.plain).offset(x: x - hitWidth / 2)
                }
                Circle().fill(Color.gray.opacity(0.55)).frame(width: knobSize, height: knobSize)
                    .shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 1).offset(x: knobX - knobSize/2)
            }
            .frame(height: g.size.height).contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { val in
                let localX = min(max(0, val.location.x), w)
                value = Double((localX / w) * 100)
            })
        }
    }
}

struct PortfolioRowView: View {
    let asset: AssetItem
    var body: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Image(asset.iconName).resizable().scaledToFit().frame(width: 35, height: 35).clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 2.5) {
                Text(asset.name)
                    .font(.app(size: 16, weight: .semibold))
                    .foregroundColor(.TextPrimary)
                
                Text(asset.symbol)
                    .font(.app(size: 14.5, weight: .medium))
                  .foregroundColor(.TextSecondary)
                }
            
            Spacer()
            VStack(alignment: .trailing, spacing: 2.5) {
                Text(asset.balanceValue)
                    .font(.app(size: 16, weight: .semibold))
                    .foregroundColor(.TextPrimary)
                
                Text(asset.balanceAmount)
                    .font(.app(size: 14.5, weight: .medium))
                    .foregroundColor(.TextSecondary)
            }
        }.padding(.vertical, 8).padding(.horizontal, 16).background(Color.bg)
    }
}

//struct PortfolioRowView: View {
//    let asset: AssetItem
//    var body: some View {
//        HStack(spacing: 8) {
//            ZStack(alignment: .bottomTrailing) {
//                if asset.iconName.hasPrefix("http") {
//                    AsyncImage(url: URL(string: asset.iconName)) { phase in
//                        if let image = phase.image { image.resizable().scaledToFit() }
//                        else if phase.error != nil { Image(systemName: "questionmark.circle").foregroundColor(.gray) }
//                        else { ProgressView() }
//                    }.frame(width: 35, height: 35).clipShape(Circle())
//                } else {
//                    Image(asset.iconName).resizable().scaledToFit().frame(width: 35, height: 35).clipShape(Circle())
//                }
//            }
//            VStack(alignment: .leading, spacing: 2) {
//                Text(asset.name).font(.app(size: 16, weight: .semibold)).foregroundColor(.TextPrimary)
//                Text(asset.symbol).font(.app(size: 14.5, weight: .medium)).foregroundColor(.TextSecondary)
//            }
//            Spacer()
//            VStack(alignment: .trailing, spacing: 2) {
//                Text(asset.balanceValue).font(.app(size: 16, weight: .semibold)).foregroundColor(.TextPrimary)
//                Text(asset.balanceAmount).font(.app(size: 14.5, weight: .medium)).foregroundColor(.TextSecondary)
//            }
//        }.padding(.vertical, 9).padding(.horizontal, 16).background(Color.bg)
//    }
//}

struct HistoryCard: View {
    let item: HistoryItem
    
    var body: some View {
        VStack(spacing: 10) {
            
            HStack {
                HStack(spacing: 8) {
                    
                    Image(item.iconSymbol)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .clipShape(Circle())
                    
                    Text(item.symbol)
                        .font(.app(size: 18, weight: .semibold))
                        .foregroundColor(.TextPrimary)
                }
            
                Spacer()
            
                Text(item.type)
                    .font(.app(size: 18, weight: .semibold))
                    .foregroundColor(.TextPrimary)
            
                Text(item.status)
                    .font(.app(size: 12, weight: .semibold))
                    .foregroundColor(Color.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(15)
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            detailRow(label: "Time", value: item.time)
            HStack {
                Text("Price")
                    .foregroundColor(.TextPrimary)
                    .font(.app(size: 16, weight: .medium))
                Spacer()
                            
                let priceVal = Double(item.price.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0
                SmartPriceText(value: priceVal, fontSize: 16, weight: .medium)
            }
            if item.type.caseInsensitiveCompare("Sell") == .orderedSame {
            
                detailRow(label: "Sell", value: item.sellAmount, valueColor: .red)
            } else {
                detailRow(label: "Buy", value: item.buyAmount, valueColor: .green)
            }
            
            detailRow(label: "Gas Fee", value: item.gasFee)
        }
        .padding(14)
        .background(Color("HistoryCard"))
        .cornerRadius(10)
        
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    func detailRow(label: String, value: String, valueColor: Color = .TextPrimary) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.TextPrimary)
                .font(.app(size: 16, weight: .medium))
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .font(.app(size: 16, weight: .medium))
        }
    }
}

private struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct TransactionDetail: View {
    let item: HistoryItem
    @Environment(\.dismiss) var dismiss
    @State private var contentHeight: CGFloat = 0
    private let minSheetPadding: CGFloat = 100
    private let maxScreenFraction: CGFloat = 0.90

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()

            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    Text("Transaction Details")
                        .foregroundColor(.TextPrimary)
                        .font(.app(size: 18, weight: .semibold))
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.gray)
                    }
                }
                .padding()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Image(item.iconSymbol)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 27, height: 27)
                                    .clipShape(Circle())
                            
                                Text(item.symbol)
                                    .font(.app(size: 20, weight: .semibold))
                                    .foregroundColor(.TextPrimary)
                            
                                Spacer()
                                
                                Text(item.type)
                                    .font(.app(size: 18, weight: .semibold))
                                    .foregroundColor(.TextPrimary)

                                Text(item.status)
                                    .font(.app(size: 15, weight: .semibold))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(15)
                            }
                            
                            Divider().background(Color.white.opacity(0.2))
           
                            Group {
                                detailRow(label: "Time", value: item.time)
                                detailRow(label: "Price", value: item.price)
                             
                                if item.type.caseInsensitiveCompare("Sell") == .orderedSame {
                                    detailRow(label: "Sell", value: item.sellAmount, valueColor: .red)
                                    detailRow(label: "Received", value: item.buyAmount, valueColor: .green)
                                } else {
                                    detailRow(label: "Buy", value: item.buyAmount, valueColor: .green)
                                    if !item.sellAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        detailRow(label: "Using", value: item.sellAmount, valueColor: .red)
                                    }
                                }
                                
                                detailRow(label: "Gas Fee", value: item.gasFee)
                                
                                if !item.appFee.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    detailRow(label: "App Fee", value: item.appFee)
                                }
                            }
                        }
                        .padding(5)
                        .background(Color("AppBackground"))
              
                        VStack(spacing: 0) {
                          
                            if let target = item.targetTx {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 4) {
                                        Text("Target Tx Hash on")
                                            .font(.app(size: 17, weight: .semibold))
                                            .foregroundColor(.TextPrimary)
                                    
                                        Text(target.networkName)
                                            .font(.app(size: 17, weight: .semibold))
                                            .foregroundColor(.TextPrimary)
                                    }
                                    hashRow(label: "Tx Hash", network: target.networkName, hash: target.txHash)
                                }
                                .padding(.horizontal, 4)
                                .padding(.bottom, 10)
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                    
                            if let settlement = item.settlementTx {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 4) {
                                        Text("Settlement Tx Hash on")
                                            .font(.app(size: 17, weight: .semibold))
                                            .foregroundColor(.TextPrimary)
                                    
                                        Text(settlement.networkName)
                                            .font(.app(size: 17, weight: .semibold))
                                            .foregroundColor(.TextPrimary)
                                    }
                                    hashRow(label: "Tx Hash", network: settlement.networkName, hash: settlement.txHash)
                                }
                                .padding(.top, 20)
                                .padding(.horizontal, 4)
                                .padding(.bottom, 10)
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                   
                            ForEach(item.sourceTxs) { source in
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 4) {
                                        Text("From Tx Hash on")
                                            .font(.app(size: 17, weight: .semibold))
                                            .foregroundColor(.TextPrimary)

                                        Text(source.networkName)
                                            .font(.app(size: 17, weight: .semibold))
                                            .foregroundColor(.TextPrimary)
                                    }

                                    hashRow(label: "Tx Hash", network: source.networkName, hash: source.txHash)
                                }
                                .padding(.top, 20)
                                .padding(.horizontal, 4)
                                .padding(.bottom, 10)

                                if source.id != item.sourceTxs.last?.id {
                                    Divider().background(Color.white.opacity(0.1))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 5)
                    .background(
                        GeometryReader { g in
                            Color.clear.preference(key: ViewHeightKey.self, value: g.size.height)
                        }
                    )
                }
                .scrollContentBackground(.hidden)
            }
        }
        .onPreferenceChange(ViewHeightKey.self) { newH in
            withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.9, blendDuration: 0)) {
                if abs(newH - contentHeight) > 0.5 {
                    contentHeight = newH
                }
            }
        }
        .presentationDetents([
            .height(min(max(minSheetPadding + contentHeight, 180), UIScreen.main.bounds.height * maxScreenFraction))
        ])
        .presentationBackground(.clear)
    }

    func detailRow(label: String, value: String, valueColor: Color = .TextPrimary) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
                .font(.app(size: 18, weight: .semibold))
           
            Spacer()
           
            Text(value)
                .foregroundColor(valueColor)
                .font(.app(size: 18, weight: .semibold))
        }
    }
 
    func hashRow(label: String, network: String, hash: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
                .font(.app(size: 16))
           
            Spacer()
           
            let content = HStack(spacing: 4) {
                Text(shortenHash(hash))
                    .foregroundColor(.gray)
                    .font(.app(size: 16))
               
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }
            if let url = getExplorerURL(network: network, hash: hash) {
                Link(destination: url) {
                    content
                }
            } else {
                content
            }
        }
    }
    
    func shortenHash(_ hash: String) -> String {
        guard hash.count > 10 else { return hash }
        return hash.prefix(6) + "..." + hash.suffix(4)
    }
}

struct SlippageSettingsView: View {
    @Binding var slippage: Double?
    @Binding var customSlippage: String
    @Binding var solanaTxMode: String
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ZStack {
                    Text("Slippage Settings")
                        .font(.app(size: 20, weight: .bold))
                        .foregroundColor(Color("TextPrimary"))

                    HStack {
                        Button(action: {
                            withAnimation { isPresented = false }
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color("TextPrimary"))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 30)

                VStack(alignment: .leading, spacing: 30) {
                 
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Slippage Tolerance")
                                .font(.app(size: 16, weight: .semibold))
                                .foregroundColor(Color("TextPrimary"))
                            
                            Text("Sets the allowed price difference during execution.")
                                .font(.app(size: 14))
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        HStack(spacing: 8) {
                            slippageButton(title: "Auto", isSelected: slippage == nil && customSlippage.isEmpty) {
                                slippage = nil
                                customSlippage = ""
                            }
                          
                            ForEach([0.5, 1.0], id: \.self) { val in
                                slippageButton(title: "\(String(format: "%g", val))%", isSelected: slippage == val) {
                                    slippage = val
                                    customSlippage = ""
                                }
                            }
                         
                            HStack(spacing: 0) {
                                Spacer()
                                TextField("", text: $customSlippage)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.app(size: 15, weight: .semibold))
                                    .foregroundColor(Color("TextPrimary"))
                                    .onChange(of: customSlippage) { _, newValue in
                                        handleCustomSlippageInput(newValue)
                                    }
                                Text(" %")
                                    .font(.app(size: 15, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(!customSlippage.isEmpty ? Color("TextPrimary").opacity(0.1) : Color.clear)
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("TextPrimary").opacity(0.15), lineWidth: 1)
                                }
                            )
                        }
                    }
                 
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Solana TX mode")
                                .font(.app(size: 16, weight: .semibold))
                                .foregroundColor(Color("TextPrimary"))
                            
                            Text("How your swap is sent to the network.")
                                .font(.app(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 0) {
                            ForEach(["Auto", "Jito", "Classic"], id: \.self) { mode in
                                Button(action: { solanaTxMode = mode }) {
                                    Text(mode)
                                        .font(.app(size: 15, weight: .semibold))
                                        .foregroundColor(solanaTxMode == mode ? Color("TextPrimary") : .gray)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 45)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(solanaTxMode == mode ? Color("TextPrimary").opacity(0.15) : Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("TextPrimary").opacity(0.05))
                        )
                    }
                }
                .padding(.horizontal, 17)
                
                Spacer()
            
                HStack(spacing: 12) {
                    Button(action: {
                        slippage = nil
                        customSlippage = ""
                        solanaTxMode = "Auto"
                    }) {
                        Text("Reset")
                            .font(.app(size: 17, weight: .bold))
                            .foregroundColor(Color("TextSecondary"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("TextPrimary").opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation { isPresented = false }
                    }) {
                        Text("Done")
                            .font(.app(size: 17, weight: .bold))
                            .foregroundColor(Color("AppBackground"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color("TextPrimary"))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private func slippageButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.app(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? Color("TextPrimary") : .gray)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color("TextPrimary").opacity(0.1) : Color.clear)
                              
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("TextPrimary").opacity(0.15), lineWidth: 1)
                    }
               )
        }
        .buttonStyle(.plain)
    }
    
    private func handleCustomSlippageInput(_ newValue: String) {
        let filtered = newValue.filter { "0123456789.".contains($0) }
        
        if filtered != newValue {
            customSlippage = filtered
            return
        }
        
        if let val = Double(filtered) {
            if val > 100 {
                customSlippage = "100"
                slippage = 100.0
            } else {
                slippage = val
            }
        } else if filtered.isEmpty {
            slippage = nil
        }
    }
}

#Preview {
    Trade(marketVM: MarketViewModel())
}
