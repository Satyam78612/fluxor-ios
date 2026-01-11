//
//  Earn.swift
//  Fluxor
//
//  Created by Satyam Singh on 22/11/25.
//

import SwiftUI

struct DarkCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color("SwapCardBackground"))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color("DividerColor").opacity(0.5), lineWidth: 0.5)
            )
    }
}

extension View {
    func darkCardStyle() -> some View {
        self.modifier(DarkCardModifier())
    }
}

struct LeaderboardUser: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let points: String
}

@ViewBuilder
fileprivate func rankIconView(rank: Int) -> some View {
    switch rank {
    case 1:
        Image("Gold_badge")
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        
    case 2:
        Image("Silver_badge")
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipShape(Circle())

    case 3:
        Image("Bronze_badge")
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipShape(Circle())

    default:
        Text("#\(rank)")
            .font(.app(size: 14, weight: .medium))
            .foregroundColor(Color("TextSecondary"))
            .frame(width: 40, height: 40, alignment: .center)
    }
}

struct Earn: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedTab: String = "Points"
    @Namespace private var animation
    
    let tabs = ["Points", "Leaderboard"]
    let referralLink = "https://fluxor.fi/ref/FLUX2025"

    let leaderboardData = [
        LeaderboardUser(rank: 1, name: "Crypto Whale", points: "100,020"),
        LeaderboardUser(rank: 2, name: "DeFi Master", points: "81,202"),
        LeaderboardUser(rank: 3, name: "Yield Farmer", points: "67,239"),
        LeaderboardUser(rank: 4, name: "Bull Trader", points: "45,032"),
        LeaderboardUser(rank: 5, name: "Token Hunter", points: "31,343"),
        LeaderboardUser(rank: 6, name: "Swap Ninja", points: "21,232"),
        LeaderboardUser(rank: 7, name: "Monster", points: "18,239"),
        LeaderboardUser(rank: 8, name: "Swap Legend", points: "13,453"),
        LeaderboardUser(rank: 9, name: "Intern", points: "11,323"),
        LeaderboardUser(rank: 10, name: "Pro Trader", points: "9,033"),
        LeaderboardUser(rank: 11, name: "Aplpha Hunter", points: "7,332"),
        LeaderboardUser(rank: 12, name: "TraderZero", points: "5,434")
    ]

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    HStack(spacing: 0) {
                        ForEach(tabs, id: \.self) { tab in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            }) {
                                ZStack {
                                    if selectedTab == tab {
                                        RoundedRectangle(cornerRadius: 11)
                                            .fill(Color("TextSecondary").opacity(0.2))
                                            .matchedGeometryEffect(id: "TabBackground", in: animation)
                                    }

                                    Text(tab)
                                        .font(.app(size: 16, weight: .medium))
                                        .foregroundColor(
                                            selectedTab == tab
                                            ? Color("TextPrimary")
                                            : Color("TextSecondary")
                                        )
                                        .padding(.vertical, 8)
                                }
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(Color("SwapCardBackground"))
                    .cornerRadius(15)
                    .frame(width: 260)
                    .padding(.top, -8)

                    Group {
                        if selectedTab == "Points" {
                            pointsView
                        } else {
                            leaderboardView
                        }
                    }
                }
                .padding(.top)
            }
        }
    }

    var pointsView: some View {
        VStack(spacing: 20) {
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Your Points")
                    .font(.app(size: 16, weight: .medium))
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.bottom, 7)
                    .padding(.top, -8)
                
                Text("6,452")
                    .font(.app(size: 35, weight: .bold))
                    .foregroundColor(Color("TextPrimary"))
                
                Spacer()
                
                Text("Rank: 1,343")
                    .font(.app(size: 18, weight: .semibold))
                    .foregroundColor(Color("TextPrimary"))
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 200)
            .background(Color("EarnCard"))
            .cornerRadius(23)
            .overlay(alignment: .topTrailing) {
            
                Image("Fluxor")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .padding(8)
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                statRow(title: "Referrals", value: "129 Users")
                statRow(title: "Referral Points", value: "3,427 Points")
                statRow(title: "Weekly Distribution", value: "100,000 Points")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, -2)

            VStack(alignment: .leading, spacing: 15) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Share and earn")
                        .font(.app(size: 20, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))
                    
                    Text("Share your referral link and earn 10% of your referral's points (up to 20k).")
                        .font(.app(size: 14.5, weight: .medium))
                        .foregroundColor(Color("TextSecondary"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)

                HStack {
                    Text(referralLink)
                        .font(.app(size: 15, weight: .medium))
                        .foregroundColor(Color("TextPrimary"))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {
                        UIPasteboard.general.string = referralLink
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: "square.on.square")
                            .font(.app(size: 16))
                            .foregroundColor(Color("TextSecondary"))
                    }
                }
                .padding()
                .background(Color("SwapCardBackground"))
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("DividerColor").opacity(0.5), lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
            }
            .padding(.top, 10)
            
            Spacer().frame(height: 50)
        }
    }

    var leaderboardView: some View {
        VStack(spacing: 5) {
            Text("Top Traders")
                .font(.app(size: 20, weight: .bold))
                .foregroundColor(Color("TextPrimary"))

            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    Text("Rank").frame(width: 44.2).padding(.leading, -6)
                    Text("Name").padding(.leading, 12)
                    
                    Spacer()
                    Text("Points")
                }
                .font(.app(size: 13.5, weight: .medium))
                .foregroundColor(Color("TextSecondary"))
                .padding(.horizontal)
                .padding(.bottom, 8)

                Divider().background(Color("DividerColor"))

                ForEach(leaderboardData) { user in
                    
                    HStack(alignment: .center, spacing: 16.5) {
                        HStack(alignment: .center, spacing: 15.3) {
                            rankIconView(rank: user.rank)
                                .frame(width: 40, height: 40)
                                .padding(.leading, -5)

                            Text(user.name)
                                .font(.app(size: 16, weight: .medium))
                                .foregroundColor(Color("TextPrimary"))
                        }

                        Spacer()

                        Text(user.points)
                            .font(.app(size: 16, weight: .medium))
                            .foregroundColor(Color(.green))
                    }
                    .padding(.vertical, 9)
                    .padding(.horizontal)
                    .background(Color("AppBackground"))
                    
                    Divider().background(Color("DividerColor").opacity(0.5))
                }
            }
            .padding(.top)
        }
    }
    
    @ViewBuilder
    func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.app(size: 17.5, weight: .medium))
                .foregroundColor(Color("TextSecondary"))
            
            Spacer()
            
            Text(value)
                .font(.app(size: 17.5, weight: .semibold))
                .foregroundColor(Color("TextPrimary"))
        }
    }
}

#Preview {
    Earn()
}
