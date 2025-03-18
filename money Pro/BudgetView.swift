import SwiftUI

struct BudgetView: View {
    @ObservedObject var transactionStore: TransactionStore
    @ObservedObject var budgetStore: BudgetStore
    @State private var showingAddBalance = false
    @State private var newBalanceName = ""
    @State private var newBalanceAmount = ""
    @State private var transferAmount = ""
    @State private var selectedSourceBalanceId: UUID?
    @State private var selectedDestinationBalanceId: UUID?
    
    private var totalBalance: Double {
        budgetStore.balances.reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        transactionStore.transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        transactionStore.transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Balances")) {
                    ForEach(budgetStore.balances) { balance in
                        HStack {
                            Text(balance.name)
                            Spacer()
                            Text("R\(balance.amount, specifier: "%.2f")")
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                budgetStore.deleteBalance(balance)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                
                Section(header: Text("Transfer Funds")) {
                    if budgetStore.balances.count < 2 {
                        Text("Please add at least two accounts to make a transfer.")
                            .foregroundColor(.gray)
                    } else {
                        Picker("From Account", selection: $selectedSourceBalanceId) {
                            ForEach(budgetStore.balances) { balance in
                                Text(balance.name).tag(Optional(balance.id))
                            }
                        }
                        Picker("To Account", selection: $selectedDestinationBalanceId) {
                            ForEach(budgetStore.balances) { balance in
                                Text(balance.name).tag(Optional(balance.id))
                            }
                        }
                        TextField("Amount", text: $transferAmount)
                            .keyboardType(.decimalPad)
                        Button("Transfer") {
                            performTransfer()
                        }
                        .disabled(selectedSourceBalanceId == nil || selectedDestinationBalanceId == nil || transferAmount.isEmpty)
                    }
                }
                
                Section(header: Text("Transfers")) {
                    ForEach(transactionStore.transactions.filter { $0.type == .expense && $0.title.contains("Transfer") }) { transaction in
                        HStack {
                            Text(transaction.title)
                            Spacer()
                            Text("R\(transaction.amount, specifier: "%.2f")")
                                .foregroundColor(transaction.amount < 0 ? .red : .green)
                        }
                    }
                }
                
                Section(header: Text("Other Transactions")) {
                    ForEach(transactionStore.transactions.filter { !($0.type == .expense && $0.title.contains("Transfer")) }) { transaction in
                        HStack {
                            Text(transaction.title)
                            Spacer()
                            Text("R\(transaction.amount, specifier: "%.2f")")
                                .foregroundColor(transaction.amount < 0 ? .red : .green)
                        }
                    }
                }
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Balance") {
                        showingAddBalance = true
                    }
                }
            }
            .alert("Add Balance", isPresented: $showingAddBalance) {
                TextField("Account Name", text: $newBalanceName)
                TextField("Amount", text: $newBalanceAmount)
                    .keyboardType(.decimalPad)
                
                Button("Cancel", role: .cancel) {
                    newBalanceName = ""
                    newBalanceAmount = ""
                }
                
                Button("Add") {
                    if let amount = Double(newBalanceAmount) {
                        let balance = Balance(name: newBalanceName, amount: amount)
                        budgetStore.addBalance(balance)
                        newBalanceName = ""
                        newBalanceAmount = ""
                    }
                }
            } message: {
                Text("Enter the details for the new balance account")
            }
        }
    }
    
    private func performTransfer() {
        guard let sourceId = selectedSourceBalanceId,
              let destinationId = selectedDestinationBalanceId,
              let amount = Double(transferAmount),
              sourceId != destinationId else { return }
        
        if let sourceIndex = budgetStore.balances.firstIndex(where: { $0.id == sourceId }),
           let destinationIndex = budgetStore.balances.firstIndex(where: { $0.id == destinationId }) {
            
            var updatedBalances = budgetStore.balances
            updatedBalances[sourceIndex].amount -= amount
            updatedBalances[destinationIndex].amount += amount
            budgetStore.balances = updatedBalances
            
            let sourceTransaction = Transaction(
                title: "Transfer to \(budgetStore.balances[destinationIndex].name)",
                amount: -amount,
                date: Date(),
                type: .expense,
                balanceAccountId: sourceId
            )
            let destinationTransaction = Transaction(
                title: "Transfer from \(budgetStore.balances[sourceIndex].name)",
                amount: amount,
                date: Date(),
                type: .income,
                balanceAccountId: destinationId
            )
            
            transactionStore.addTransaction(sourceTransaction)
            transactionStore.addTransaction(destinationTransaction)
            
            transferAmount = ""
            selectedSourceBalanceId = nil
            selectedDestinationBalanceId = nil
        }
    }
}

#Preview {
    BudgetView(transactionStore: TransactionStore(), budgetStore: BudgetStore())
}

extension BudgetStore {
    func deleteBalance(_ balance: Balance) {
        if let index = balances.firstIndex(where: { $0.id == balance.id }) {
            balances.remove(at: index)
            saveBalances()
        }
    }
} 