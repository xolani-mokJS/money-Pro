import SwiftUI

struct HomeView: View {
    @ObservedObject var transactionStore: TransactionStore
    @ObservedObject var budgetStore: BudgetStore
    @AppStorage("userName") private var userName: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    welcomeSection
                    balanceCard
                    recentTransactionsSection
                }
                .padding(.vertical, 12)
            }
            .background(Color(.systemGray6))
            .navigationBarHidden(true)
        }
    }
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hello, \(userName)")
                .font(.title)
                .fontWeight(.bold)
            Text("Welcome back to Money Pro")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Balance")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                    Text("R\(totalBalance, specifier: "%.2f")")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "creditcard.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Divider()
                .background(.white.opacity(0.5))
            
            HStack(spacing: 40) {
                balanceInfoView(title: "Income", amount: totalIncome)
                balanceInfoView(title: "Expenses", amount: totalExpenses)
            }
        }
        .padding(16)
        .background(balanceCardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 8)
        .padding(.horizontal)
    }
    
    private var balanceCardGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue,
                Color.blue.opacity(0.8),
                Color(red: 0.2, green: 0.5, blue: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func balanceInfoView(title: String, amount: Double) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            Text("R\(amount, specifier: "%.2f")")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Transactions")
                .font(.headline)
                .padding(.horizontal)
            
            if transactionStore.transactions.isEmpty {
                Text("No transactions yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                LazyVStack(spacing: 0) {
                    let transactions = Array(transactionStore.transactions
                        .sorted(by: { $0.date > $1.date })
                        .prefix(5))
                    
                    ForEach(transactions) { transaction in
                        VStack {
                            TransactionRowView(transaction: transaction)
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                            
                            if transaction.id != transactions.last?.id {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                
                NavigationLink(destination: TransactionsView(store: transactionStore, budgetStore: budgetStore)) {
                    HStack {
                        Text("See All Transactions")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var totalBalance: Double {
        budgetStore.balances.reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        transactionStore.transactions
            .filter { $0.type == .income && !$0.title.contains("Transfer") }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        transactionStore.transactions
            .filter { $0.type == .expense && !$0.title.contains("Transfer") }
            .reduce(0) { $0 + abs($1.amount) }
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.system(.body, design: .default))
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("R\(transaction.amount, specifier: "%.2f")")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(transaction.type == .income ? .green : .red)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
}

#Preview {
    HomeView(transactionStore: TransactionStore(), budgetStore: BudgetStore())
} 