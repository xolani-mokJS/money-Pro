import SwiftUI

struct Transaction: Identifiable, Codable {
    let id: UUID
    let title: String
    let amount: Double
    let date: Date
    let type: TransactionType
    let balanceAccountId: UUID
    
    init(id: UUID = UUID(), title: String, amount: Double, date: Date, type: TransactionType, balanceAccountId: UUID) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.type = type
        self.balanceAccountId = balanceAccountId
    }
    
    enum TransactionType: String, Codable {
        case income
        case expense
    }
}

class TransactionStore: ObservableObject {
    @Published var transactions: [Transaction] = [] {
        didSet {
            saveTransactions()
        }
    }
    
    init() {
        loadTransactions()
    }
    
    private func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: "SavedTransactions")
        }
    }
    
    private func loadTransactions() {
        if let savedTransactions = UserDefaults.standard.data(forKey: "SavedTransactions") {
            if let decodedTransactions = try? JSONDecoder().decode([Transaction].self, from: savedTransactions) {
                transactions = decodedTransactions
            }
        }
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
    }
    
    func deleteTransaction(at offsets: IndexSet) {
        transactions.remove(atOffsets: offsets)
    }
}

struct Balance: Identifiable, Codable {
    let id: UUID
    let name: String
    var amount: Double
    
    init(id: UUID = UUID(), name: String, amount: Double) {
        self.id = id
        self.name = name
        self.amount = amount
    }
}

class BudgetStore: ObservableObject {
    @Published var balances: [Balance] = [] {
        didSet {
            saveBalances()
        }
    }
    
    init() {
        loadBalances()
    }
    
    func saveBalances() {
        if let encoded = try? JSONEncoder().encode(balances) {
            UserDefaults.standard.set(encoded, forKey: "SavedBalances")
        }
    }
    
    private func loadBalances() {
        if let savedBalances = UserDefaults.standard.data(forKey: "SavedBalances") {
            if let decodedBalances = try? JSONDecoder().decode([Balance].self, from: savedBalances) {
                balances = decodedBalances
            }
        }
    }
    
    func addBalance(_ balance: Balance) {
        balances.append(balance)
    }
    
    func removeBalance(at offsets: IndexSet) {
        balances.remove(atOffsets: offsets)
    }
    
    func updateBalanceForTransaction(_ transaction: Transaction) {
        if let index = balances.firstIndex(where: { $0.id == transaction.balanceAccountId }) {
            var updatedBalances = balances
            let amount = transaction.type == .income ? transaction.amount : -transaction.amount
            let newBalance = Balance(
                id: updatedBalances[index].id,
                name: updatedBalances[index].name,
                amount: updatedBalances[index].amount + amount
            )
            updatedBalances[index] = newBalance
            balances = updatedBalances
        }
    }
} 