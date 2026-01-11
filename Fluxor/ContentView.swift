//
//  ContentView.swift
//  Fluxor
//
//  Created by Satyam Singh on 20/11/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @ObservedObject var marketVM: MarketViewModel

    var body: some View {
        if isLoggedIn {
            MainTab(marketVM: marketVM)
        } else {
            Login()
        }
    }
}

#Preview {
    ContentView(marketVM: MarketViewModel())
}
