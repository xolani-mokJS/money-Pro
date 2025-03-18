import SwiftUI

struct TransactionsView: View {
    @ObservedObject var store: TransactionStore
    @ObservedObject var budgetStore: BudgetStore
    @State private var showingAddTransaction = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.transactions.sorted(by: { $0.date > $1.date })) { transaction in
                    TransactionRowView(transaction: transaction)
                }
                .onDelete(perform: deleteTransaction)
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTransaction = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView(store: store, budgetStore: budgetStore)
            }
        }
    }
    
    private func deleteTransaction(at offsets: IndexSet) {
        store.transactions.remove(atOffsets: offsets)
        store.saveTransactions()
    }
}

#Preview {
    TransactionsView(store: TransactionStore(), budgetStore: BudgetStore())
} 