//
//  Login.swift
//  Fluxor
//
//  Created by Satyam Singh on 22/11/25.
//

import SwiftUI

struct Login: View {
    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()
            
            VStack {
                Spacer().frame(height: 35)
                
                Image("Fluxor")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                
                Text("Welcome to Fluxor")
                    .font(.app(size: 35, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Text("The First Chain-agnostic DEX with an intuitive experience. Trade, Invest, and Earn without the complexity of bridges, chains, or gas.")
                    .font(.app(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 5)
                    .lineSpacing(4)
                
                Spacer()
                
                VStack(spacing: 15) {
                    Button(action: {}) {
                        Text("Sign Up")
                            .font(.app(size: 23, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(20)
                    }
                    
                    Button(action: {}) {
                        Text("Log In")
                            .font(.app(size: 25, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color(red: 160/255, green: 64/255, blue: 255/255))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 35)
                .padding(.bottom, 100)
            }
        }
    }
}

#Preview {
    Login()
}
