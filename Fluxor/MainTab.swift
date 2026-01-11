//
//  MainTab.swift
//  Fluxor
//
//  Created by Satyam Singh on 22/11/25.
//

import SwiftUI

enum MainTabItem: String {
    case home = "Home"
    case market = "Market"
    case trade = "Trade"
    case earn = "Earn"
    case wallet = "Wallet"
}

struct MainTab: View {
    @State private var selected: MainTabItem = .home
    @ObservedObject var marketVM: MarketViewModel

    var body: some View {
        ZStack {
            Group {
                switch selected {
                case .home: Home(marketVM: marketVM)
                case .market: Market(viewModel: marketVM)
                case .trade:  Trade(marketVM: marketVM)
                case .earn:   Earn()
                case .wallet: Wallet()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("AppBackground").ignoresSafeArea())

            VStack {
                Spacer()
                HStack {
                    tabButton(.home,   systemImage: "house.fill")
                    tabButton(.market, systemImage: "chart.bar.xaxis")
                    tabButton(.trade,  systemImage: "rectangle.2.swap")
                    tabButton(.earn,   systemImage: "gift.fill")
                    tabButton(.wallet, systemImage: "wallet.bifold.fill")
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 2)
                .background(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -5)
            }
        }
    }

    func tabButton(_ tab: MainTabItem, systemImage: String) -> some View {
        Button {
            selected = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                
                Text(tab.rawValue)
                    .font(.app(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(
                selected == tab ? Color("TextPrimary") : Color.gray
            )
        }
    }
}

#Preview {
    MainTab(marketVM: MarketViewModel())
}
