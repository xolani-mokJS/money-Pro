import SwiftUI

struct TransactionsView: View {
    @ObservedObject var store: TransactionStore
    @ObservedObject var budgetStore: BudgetStore
    @State private var showingAddTransaction = false
    @State private var showingDeleteConfirmation = false
    @State private var transactionToDelete: IndexSet?
    
    private var totalBalance: Double {
        budgetStore.balances.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Balance Card
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available Balance")
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            Text("R\(totalBalance, specifier: "%.2f")")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Image(systemName: "creditcard.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Divider()
                        .background(.white.opacity(0.5))
                    
                    HStack(alignment: .bottom) {
                        Text("Money Pro")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Image(systemName: "wave.3.right")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue,
                            Color.blue.opacity(0.8),
                            Color(red: 0.2, green: 0.5, blue: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 10)
                .padding(.horizontal)
                
                // Transactions List
                List {
                    ForEach(store.transactions.sorted(by: { $0.date > $1.date })) { transaction in
                        TransactionRow(transaction: transaction, balanceName: balanceName(for: transaction))
                    }
                    .onDelete { offsets in
                        transactionToDelete = offsets
                        showingDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView(store: store, budgetStore: budgetStore)
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Transaction"),
                    message: Text("Are you sure you want to delete this transaction?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let offsets = transactionToDelete {
                            for index in offsets {
                                let transaction = store.transactions[index]
                                budgetStore.updateBalanceForTransaction(Transaction(
                                    id: transaction.id,
                                    title: transaction.title,
                                    amount: -transaction.amount,
                                    date: transaction.date,
                                    type: transaction.type,
                                    balanceAccountId: transaction.balanceAccountId
                                ))
                            }
                            store.deleteTransaction(at: offsets)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func balanceName(for transaction: Transaction) -> String {
        budgetStore.balances.first { $0.id == transaction.balanceAccountId }?.name ?? "Unknown Account"
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let balanceName: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.headline)
                HStack {
                    Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    Text("•")
                    Text(balanceName)
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(transaction.type == .income ? "R \(transaction.amount, specifier: "%.2f")" : "-R \(transaction.amount, specifier: "%.2f")")
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(transaction.type == .income ? .green : .red)
        }
        .padding(.vertical, 4)
    }
} 