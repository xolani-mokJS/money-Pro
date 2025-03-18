//
//  ContentView.swift
//  money Pro
//
//  Created by Xolani Mokhoebane on 2025/03/18.
//

import SwiftUI

struct ContentView: View {
    @StateObject var transactionStore = TransactionStore()
    @StateObject var budgetStore = BudgetStore()
    @State private var showingNamePrompt = false
    @AppStorage("userName") private var userName: String = ""
    
    var body: some View {
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
                    Label("Budget", systemImage: "chart.pie")
                }
        }
        .navigationTitle("Hello, \(userName)")
        .onAppear {
            if userName.isEmpty {
                showingNamePrompt = true
            }
        }
        .sheet(isPresented: $showingNamePrompt) {
            NamePromptView(userName: $userName, isPresented: $showingNamePrompt)
        }
    }
}

struct NamePromptView: View {
    @Binding var userName: String
    @Binding var isPresented: Bool
    @State private var tempName: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to Money Pro!")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 30)
                
                Text("Please enter your name to get started")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("Your Name", text: $tempName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Get Started") {
                    if !tempName.isEmpty {
                        userName = tempName
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(tempName.isEmpty)
                
                Spacer()
            }
            .padding()
            .interactiveDismissDisabled(true)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
