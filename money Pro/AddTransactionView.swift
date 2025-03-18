import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: TransactionStore
    @ObservedObject var budgetStore: BudgetStore
    
    @State private var title = ""
    @State private var amount = ""
    @State private var type = Transaction.TransactionType.expense
    @State private var selectedBalanceId: UUID?
    @State private var isTransfer = false
    @State private var showingAccountAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transaction Details")) {
                    TextField("Title", text: $title)
                    
                    HStack {
                        Text("R")
                            .foregroundColor(.gray)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Type", selection: $type) {
                        Text("Expense").tag(Transaction.TransactionType.expense)
                        Text("Income").tag(Transaction.TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Account")) {
                    if budgetStore.balances.isEmpty {
                        Text("Please add a balance account first")
                            .foregroundColor(.gray)
                    } else {
                        Picker("Select Account", selection: $selectedBalanceId) {
                            ForEach(budgetStore.balances) { balance in
                                Text(balance.name).tag(Optional(balance.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(title.isEmpty || amount.isEmpty || selectedBalanceId == nil)
                }
            }
        }
    }
    
    private func saveTransaction() {
        guard let balanceId = selectedBalanceId,
              let amountDouble = Double(amount) else { return }
        
        let transaction = Transaction(
            title: title,
            amount: amountDouble,
            date: Date(),
            type: type,
            balanceAccountId: balanceId
        )
        
        store.addTransaction(transaction)
        budgetStore.updateBalanceForTransaction(transaction)
        dismiss()
    }
}

#Preview {
    AddTransactionView(store: TransactionStore(), budgetStore: BudgetStore())
} 