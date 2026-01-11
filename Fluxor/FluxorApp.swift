//
//  FluxorApp.swift
//  Fluxor
//
//  Created by Satyam Singh on 20/11/25.
//

import SwiftUI
import LocalAuthentication

@main
struct FluxorApp: App {
    @AppStorage(Keys.selectedTheme) var selectedTheme: String = "Dark"
    @AppStorage(Keys.faceIDEnabled) var faceIDEnabled: Bool = false
    @AppStorage(Keys.isLoggedIn) var isLoggedIn: Bool = false
    @AppStorage(Keys.selectedLockTime) var selectedLockTime: String = "Immediately"
    
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject private var marketVM = MarketViewModel()
    @State private var isUnlocked = false
    @State private var authError: String? = nil
    @State private var lastBackgroundDate: Date? = nil
    
    var body: some Scene {
            WindowGroup {
                ZStack {
                    if isUnlocked {
                        if isLoggedIn {
                            ContentView(marketVM: marketVM)
                        } else {
                            VStack(spacing: 20) {
                                Text("Welcome to Fluxor")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Button("Log In (Test)") {
                                    isLoggedIn = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    } else {
                        UnlockView(authError: $authError, authenticate: authenticateUser)
                    }
                }
                .preferredColorScheme(selectedTheme == "Dark" ? .dark : .light)
            
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    lastBackgroundDate = Date()
                    
                    if faceIDEnabled && selectedLockTime == "Immediately" {
                        isUnlocked = false
                    }
                }
                
                if newPhase == .active {
                    checkAutoLock()
                }
            }
            .onAppear {
                if !faceIDEnabled {
                    isUnlocked = true
                } else {
                    authenticateUser()
                }
            }
        }
    }
    
    func checkAutoLock() {
        guard faceIDEnabled else { return }
        
        if let lastDate = lastBackgroundDate {
            let timeInterval = Date().timeIntervalSince(lastDate)
            
            let allowedSeconds: Double
            switch selectedLockTime {
            case "Immediately": allowedSeconds = 0
            case "5 mins": allowedSeconds = 5 * 60
            case "15 mins": allowedSeconds = 15 * 60
            case "1 hour": allowedSeconds = 60 * 60
            case "4 hours": allowedSeconds = 4 * 60 * 60
            default: allowedSeconds = 0
            }
            
            if timeInterval > allowedSeconds {
                isUnlocked = false
                authenticateUser()
            }
        }
    }
    
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Unlock Fluxor to access your crypto."
            
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                        self.authError = nil
                        self.lastBackgroundDate = nil
                    } else {
                        self.isUnlocked = false
                        self.authError = "Authentication failed."
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.isUnlocked = true
            }
        }
    }
}
    
struct UnlockView: View {
    @Binding var authError: String?
    var authenticate: () -> Void

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            VStack(spacing: 20) {

                Image(systemName: "faceid")
                    .font(.system(size: 60))
                    .foregroundColor(Color("TextPrimary"))

                Text("Fluxor Locked")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("TextPrimary"))
                if let error = authError {
                    Text(error).font(.caption).foregroundColor(.red).padding(.top, 5)
                }
                Button(action: authenticate) {
                    Text("Unlock with Face ID")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(Color("FluxorPurple"))
                        .cornerRadius(12)
                }
                .padding(.top, 20)
            }
        }
    }
}
