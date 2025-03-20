//
//  ContentView.swift
//  money Pro
//
//  Created by Xolani Mokhoebane on 2025/03/18.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var isPresented: Bool
    
    private let appBlue = Color.blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Welcome to")
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(spacing: 30) {
                Image("pie_chart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                
                Text("MONEY PRO")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            VStack(alignment: .leading, spacing: 25) {
                FeatureRow(icon: "dollarsign.square.fill", title: "Track expenses", description: "Track all your daily expenses whenever and wherever you are.")
                
                FeatureRow(icon: "chart.pie.fill", title: "Build a sustainable budget", description: "Build a budget you can rely on.")
                
                FeatureRow(icon: "graduationcap.fill", title: "Become a PRO", description: "Maybe not really a pro, but manage your money easier.")
            }
            .padding(.top, 20)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    isPresented = false
                }
            }) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(appBlue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.11, green: 0.11, blue: 0.11))
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct NamePromptView: View {
    @Binding var userName: String
    @Binding var isPresented: Bool
    @State private var tempName: String = ""
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 30) {
                Image("pie_chart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                
                Text("Welcome to\nMONEY PRO")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 50)
            
            VStack(spacing: 25) {
                Text("Let's get to know you")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Please enter your name to personalize your experience")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 20) {
                TextField("Your Name", text: $tempName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title3)
                    .padding(.horizontal, 20)
                    .focused($isNameFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if !tempName.isEmpty {
                            saveNameAndDismiss()
                        }
                    }
                
                Button(action: saveNameAndDismiss) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(tempName.isEmpty ? Color.blue.opacity(0.6) : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(tempName.isEmpty)
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFieldFocused = true
            }
        }
        .interactiveDismissDisabled(true)
    }
    
    private func saveNameAndDismiss() {
        if !tempName.isEmpty {
            userName = tempName
            withAnimation {
                isPresented = false
            }
        }
    }
}

struct ContentView: View {
    @StateObject var transactionStore = TransactionStore()
    @StateObject var budgetStore = BudgetStore()
    @State private var showingNamePrompt = false
    @State private var showingSplashScreen = true
    @AppStorage("userName") private var userName: String = ""
    
    var body: some View {
        ZStack {
            TabView {
                HomeView(transactionStore: transactionStore, budgetStore: budgetStore)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                TransactionsView(store: transactionStore, budgetStore: budgetStore)
                    .tabItem {
                        Label("Transactions", systemImage: "list.bullet")
                    }
                
                BudgetView(transactionStore: transactionStore, budgetStore: budgetStore)
                    .tabItem {
                        Label("Overview", systemImage: "chart.pie")
                    }
                
                NewBudgetView(transactionStore: transactionStore, budgetStore: budgetStore)
                    .tabItem {
                        Label("Budget", systemImage: "dollarsign.circle")
                    }
            }
            .navigationTitle("Hello, \(userName)")
            
            if showingSplashScreen {
                SplashScreenView(isPresented: $showingSplashScreen)
                    .transition(.opacity)
            }
        }
        .onChange(of: showingSplashScreen) { oldValue, newValue in
            if !newValue && userName.isEmpty {
                showingNamePrompt = true
            }
        }
        .sheet(isPresented: $showingNamePrompt) {
            NamePromptView(userName: $userName, isPresented: $showingNamePrompt)
        }
    }
}

#Preview {
    ContentView()
}
