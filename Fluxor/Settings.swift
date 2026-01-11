//
//  Settings.swift
//  Fluxor
//
//  Created by Satyam Singh on 22/11/25.
//

import SwiftUI
import PhotosUI
import LocalAuthentication

struct Keys {
    static let userProfileImage = "userProfileImage"
    static let userName = "userName"
    static let selectedTheme = "selectedTheme"
    static let isLoggedIn = "isLoggedIn"
    static let faceIDEnabled = "faceIDEnabled"
    static let selectedLockTime = "selectedLockTime"
}

struct Settings: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(Keys.selectedTheme) private var selectedTheme = "Dark"
    @AppStorage(Keys.faceIDEnabled) private var faceIDEnabled = false
    @AppStorage(Keys.selectedLockTime) private var selectedLockTime = "Immediately"
    
    @State private var showAutoLockSheet = false
    @State private var selectedCurrency = "USD"
    @State private var showCurrencySheet = false
    @State private var showThemeSheet = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()
                
                VStack(spacing: -4) {
                    
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color("TextPrimary"))
                        }
                        
                        Spacer()
                        
                        Text("Settings")
                            .font(.app(size: 20, weight: .bold))
                            .foregroundColor(Color("TextPrimary"))
                            .padding(.trailing,-18)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            
                            NavigationLink(destination: AccountProfileView()) {
                                HStack(spacing: 10) {
                                    Image("btc")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 45, height: 45)
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Satyam Singh")
                                            .font(.app(size: 22, weight: .bold))
                                            .foregroundColor(Color("TextPrimary"))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background((Color("TextSecondary").opacity(0.08)))
                                .cornerRadius(20)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            VStack(spacing: 0) {
                                ToggleSettingRow(icon: "faceid", title: "Face ID", isOn: $faceIDEnabled)
                                
                                Button(action: {
                                    showAutoLockSheet = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image("Autolock")
                                            .resizable()
                                            .renderingMode(.template)
                                            .scaledToFit()
                                            .frame(width: 35, height: 35)
                                            .foregroundColor(Color("TextPrimary"))
                                        
                                        Text("Auto lock")
                                            .font(.app(size: 19, weight: .semibold))
                                            .foregroundColor(Color("TextPrimary"))
                                        
                                        Spacer()
                                        
                                        if faceIDEnabled {
                                            Text(selectedLockTime)
                                                .font(.app(size: 18, weight: .medium))
                                                .foregroundColor(.gray)
                                        } else {
                                            Text("")
                                                .font(.app(size: 18, weight: .medium))
                                                .foregroundColor(.gray.opacity(0.7))
                                        }
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(height: 56)
                                    .padding(.horizontal)
                                    .opacity(faceIDEnabled ? 1.0 : 0.5)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(!faceIDEnabled)
                                
                                Button(action: {
                                    showCurrencySheet = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "dollarsign.circle")
                                            .font(.system(size: 20, weight: .semibold))
                                            .frame(width: 35, height: 35)
                                            .foregroundColor(Color("TextPrimary"))
                                        
                                        Text("Currency")
                                            .font(.app(size: 19, weight: .semibold))
                                            .foregroundColor(Color("TextPrimary"))
                                        
                                        Spacer()
                                        
                                        Text(selectedCurrency)
                                            .font(.app(size: 18, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(height: 56)
                                    .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                        showThemeSheet = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "sun.max")
                                            .font(.system(size: 20, weight: .semibold))
                                            .frame(width: 35, height: 35)
                                            .foregroundColor(Color("TextPrimary"))
                                        
                                        Text("Theme")
                                            .font(.app(size: 19, weight: .semibold))
                                            .foregroundColor(Color("TextPrimary"))
                                        
                                        Spacer()
                                        
                                        Text(selectedTheme)
                                            .font(.app(size: 18, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(height: 56)
                                    .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                    NavigationLink(destination: ResetAppView()) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 20, weight: .semibold))
                                                .frame(width: 35, height: 35)
                                                .foregroundColor(Color("TextPrimary"))
                                            
                                            Text("Reset App")
                                                .font(.app(size: 19, weight: .semibold))
                                                .foregroundColor(Color("TextPrimary"))
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.gray)
                                        }
                                        .frame(height: 56)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                            }
                            .background((Color("TextSecondary").opacity(0.08)))
                            .cornerRadius(20)
                            
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About Us")
                                    .font(.app(size: 17, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .padding(.leading, 5)
                                
                                VStack(spacing: 0) {
                                    
                                ExternalLinkRow(icon: "X", title: "Follow Us", url: "https://x.com/Fluxor_dex")
                                                                    
                                ExternalLinkRow(icon: "message", title: "Feedback", url: "https://t.me/Fluxor_dex")
                                                                    
                                NavigationSettingRow(icon: "hand.raised", title: "Privacy Policy", value: "", destination: Text("Privacy Policy"))
                                                                }
                                .background((Color("TextSecondary").opacity(0.08)))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        
        .sheet(isPresented: $showAutoLockSheet) {
            AutoLockSettingView(selectedTime: $selectedLockTime)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCurrencySheet) {
            CurrencySettingView(selectedCurrency: $selectedCurrency)
                .presentationDetents([.fraction(0.60)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showThemeSheet) {
            ThemeSettingView(selectedTheme: $selectedTheme)
                .presentationDetents([.fraction(0.3)])
                .presentationDragIndicator(.visible)
        }
    }
}


struct EditNameView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    
    @State private var tempName: String = ""
    
    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("TextPrimary"))
                            .padding(.leading, 4)
                    }
                    Spacer()
                    Text("Change Name")
                        .font(.app(size: 20, weight: .bold))
                        .foregroundColor(Color("TextPrimary"))
                        .padding(.trailing,-17)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.app(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                    
                    TextField("", text: $tempName)
                        .font(.app(size: 18, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))
                        .padding()
                        .background(Color("TextSecondary").opacity(0.08))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color("TextSecondary").opacity(0.1), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 16)
                
                Spacer()
               
                Button(action: {
                    if !tempName.isEmpty {
                        name = tempName
                        dismiss()
                    }
                }) {
                    Text("Confirm")
                        .font(.app(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color("FluxorPurple"))
                        .cornerRadius(16)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 60)
                .disabled(tempName.isEmpty)
                .opacity(tempName.isEmpty ? 0.6 : 1.0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            tempName = name
        }
    }
}

struct AccountProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Keys.userName) private var userName: String = "Satyam Singh"
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    
    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("TextPrimary"))
                            .padding(.leading, -10)
                    }
                    Spacer()
                    Text("Account")
                        .font(.app(size: 20, weight: .bold))
                        .foregroundColor(Color("TextPrimary"))
                        .padding(.trailing,-23)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 10)
                
                VStack(spacing: 16) {
                    
                    ZStack(alignment: .bottomTrailing) {
                        if let uiImage = profileImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color("TextSecondary").opacity(0.1), lineWidth: 1)
                                )
                        } else {
                            Image("btc")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color("TextSecondary").opacity(0.1), lineWidth: 1)
                                )
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color(UIColor.systemGray2))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color("AppBackground"), lineWidth: 3)
                                )
                        }
                        .offset(x: 0, y: 0)
                    }
                    .onAppear {
                        loadProfileImage()
                    }
            
                    NavigationLink(destination: EditNameView(name: $userName)) {
                        HStack(spacing: 8) {
                            Text(userName)
                                .font(.app(size: 26, weight: .bold))
                                .foregroundColor(Color("TextPrimary"))
                            
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 10)
                
                VStack(spacing: 0) {
                    NavigationSettingRow(
                        icon: "shield.fill",
                        title: "Account & Security",
                        value: "",
                        destination: Text("Account & Security View")
                    )
                    
                    NavigationSettingRow(
                        icon: "key.fill",
                        title: "Master Password",
                        value: "",
                        destination: Text("Master Password View")
                    )
                }
                .background(Color("TextSecondary").opacity(0.08))
                .cornerRadius(20)
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .navigationBarBackButtonHidden(true)
      
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    
                    UserDefaults.standard.set(data, forKey: Keys.userProfileImage)
                    
                    await MainActor.run {
                        withAnimation {
                            self.profileImage = uiImage
                        }
                    }
                }
            }
        }
    }
 
    func loadProfileImage() {
        if let data = UserDefaults.standard.data(forKey: Keys.userProfileImage),
           let uiImage = UIImage(data: data) {
            self.profileImage = uiImage
        }
    }
}

struct NavigationSettingRow<Destination: View>: View {
    var icon: String
    var title: String
    var value: String
    var textColor: Color = Color("TextPrimary")
    var destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                
                Group {
                    if UIImage(systemName: icon) != nil {
                        Image(systemName: icon)
                    } else {
                        Image(icon)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                    }
                }
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 35, height: 35)
                .foregroundColor(Color("TextPrimary"))
                
                Text(title)
                    .font(.app(size: 19, weight: .semibold))
                    .foregroundColor(textColor)
                
                Spacer()
                
                if !value.isEmpty {
                    Text(value)
                        .font(.app(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PlainToggleStyle: ToggleStyle {
    var tint: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? tint : Color.gray.opacity(0.3))
                .frame(width: 50, height: 26)
                .overlay(
                    Circle()
                        .fill(.white)
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10)
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        configuration.isOn.toggle()
                    }
              }
        }
    }
}

struct ToggleSettingRow: View {
    var icon: String
    var title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if UIImage(systemName: icon) != nil {
                    Image(systemName: icon)
                } else {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                }
            }
            .font(.system(size: 20, weight: .bold))
            .frame(width: 35, height: 35)
            .foregroundColor(Color("TextPrimary"))
            
            Text(title)
                .font(.app(size: 19, weight: .semibold))
                .foregroundColor(Color("TextPrimary"))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(PlainToggleStyle(tint: .purple))
        }
        .padding()
        .background(Color.clear)
    }
}

struct AutoLockSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTime: String
    let options = ["Immediately", "5 mins", "15 mins", "1 hour", "4 hours"]
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Auto lock time")
                    .font(.app(size: 22, weight: .bold))
                    .foregroundColor(Color("TextPrimary"))
                    .padding(.top, 30)
                
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            selectedTime = option
                            dismiss()
                        }) {
                            HStack {
                                Text(option)
                                    .font(.app(size: 18, weight: .semibold))
                                    .foregroundColor(Color("TextPrimary"))
                                Spacer()
                                if selectedTime == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .padding(18)
                            .background((Color("TextSecondary").opacity(0.08)))
                            .cornerRadius(15)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("AppBackground"))
      }
}

struct CurrencySettingView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCurrency: String
    
    let currencies = [
        ("USD ($)", "🇺🇸"), ("EUR (€)", "🇪🇺"), ("AUD (A$)", "🇦🇺"),
        ("INR (₹)", "🇮🇳"), ("CAD (C$)", "🇨🇦"), ("JPY (¥)", "🇯🇵"),
        ("CNY (¥)", "🇨🇳"), ("GBP (£)", "🇬🇧"), ("SGD ($)", "🇸🇬")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
           
            Text("Currency")
                .font(.app(size: 22, weight: .bold))
                .foregroundColor(Color("TextPrimary"))
                .padding(.top, 20)
                .padding(.bottom, 18)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(currencies, id: \.0) { currency, flag in
                        Button(action: {
                          
                            selectedCurrency = String(currency.prefix(3))
                            dismiss()
                        }) {
                            HStack(spacing: 15) {
                                Text(flag)
                                    .font(.app(size: 28))
                                
                                Text(currency)
                                    .font(.app(size: 18, weight: .semibold))
                                    .foregroundColor(Color("TextPrimary"))
                                
                                Spacer()
                                
                                if selectedCurrency == String(currency.prefix(3)) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .padding(15)
                            .background((Color("TextSecondary").opacity(0.08)))
                            .cornerRadius(15)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .background(Color("AppBackground").ignoresSafeArea())
    }
}

struct ThemeSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTheme: String
    
    let themes = [
        ("Light", "sun.max"),
        ("Dark", "moon")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Theme mode")
                .font(.app(size: 22, weight: .bold))
                .foregroundColor(Color("TextPrimary"))
                .padding(.top, 25)
                .padding(.bottom, 18)
            
            VStack(spacing: 12) {
                ForEach(themes, id: \.0) { name, icon in
                    Button(action: {
                        selectedTheme = name
                        dismiss()
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: icon)
                                .font(.system(size: 22, weight: .semibold))
                                .frame(width: 30)
                            
                            Text(name)
                                .font(.app(size: 19, weight: .semibold))
                                .foregroundColor(Color("TextPrimary"))
                            
                            Spacer()
                            
                            if selectedTheme == name {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .padding(16)
                        .background((Color("TextSecondary").opacity(0.08)))
                        .cornerRadius(15)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            Spacer()
        }
        .background(Color("AppBackground").ignoresSafeArea())
    }
}

struct ResetAppView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(Keys.isLoggedIn) var isLoggedIn: Bool = true
    @AppStorage(Keys.faceIDEnabled) var faceIDEnabled: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))
                        .padding(.leading, 6)
                }
                Spacer()
            }
            .padding()
            
            Spacer()
            
            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(Color("FluxorPurple").opacity(0.15))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "trash")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color("FluxorPurple"))
                }
                
                VStack(spacing: 12) {
                    Text("Reset App")
                        .font(.app(size: 26, weight: .bold))
                        .foregroundColor(Color("TextPrimary"))
                    
                    Text("Resetting your account deletes app data. Funds remain accessible by signing in again with the same email or social account.")
                        .font(.app(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                        .lineSpacing(4)
                }
            }
            
            Spacer()
      
            HStack(spacing: 16) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.app(size: 18, weight: .bold))
                        .foregroundColor(Color("TextPrimary"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color("TextSecondary").opacity(0.1))
                        .cornerRadius(16)
                }
                
            Button(action: {
                if faceIDEnabled {
                  authenticateAndReset()
                } else {
                  performReset()
                }
                }) {
                    Text("Continue")
                        .font(.app(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color("FluxorPurple"))
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 60)
        }
        .navigationBarBackButtonHidden(true)
        .background(Color("AppBackground").ignoresSafeArea())
    }

    func authenticateAndReset() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Confirm authentication to reset the app."
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.performReset()
                    } else {
                        print("Authentication failed")
                    }
                }
            }
        } else {
            performReset()
        }
    }
    
    func performReset() {
        print("Reset Confirmed - Clearing data and logging out...")
        UserDefaults.standard.removeObject(forKey: Keys.userProfileImage)
        UserDefaults.standard.removeObject(forKey: Keys.userName)
        isLoggedIn = false
    }
}

struct ExternalLinkRow: View {
    var icon: String
    var title: String
    var url: String
    
    var body: some View {
        if let linkUrl = URL(string: url) {
            Link(destination: linkUrl) {
                HStack(spacing: 12) {
                    Group {
                        if UIImage(systemName: icon) != nil {
                            Image(systemName: icon)
                        } else {
                            Image(icon)
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                        }
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 35, height: 35)
                    .foregroundColor(Color("TextPrimary"))
                    
                    Text(title)
                        .font(.app(size: 19, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    Settings()
}
