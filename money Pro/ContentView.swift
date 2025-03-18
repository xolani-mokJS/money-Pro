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
    
    private var userName: String {
        UserDefaults.standard.string(forKey: "userName") ?? ""
    }
    
    var body: some View {
        TabView {
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
    }
}

#Preview {
    ContentView()
}
