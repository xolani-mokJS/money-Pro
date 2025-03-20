import SwiftUI

struct Budget: Identifiable {
    let id = UUID()
    var name: String
    var type: BudgetType
    var period: BudgetPeriod
    var items: [BudgetItem]
    var startDate: Date
    var endDate: Date?
}

enum BudgetType: String, CaseIterable {
    case spending = "Spending"
    case debt = "Debt"
}

enum BudgetPeriod: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
}

enum ItemType: String, CaseIterable {
    case income = "Income"
    case expense = "Expense"
}

enum ItemFrequency: String, CaseIterable {
    case fixed = "Fixed"
    case variable = "Variable"
}

struct BudgetItem: Identifiable {
    let id = UUID()
    var name: String
    var amount: Double
    var type: ItemType
    var frequency: ItemFrequency
    var category: String
    var date: Date
}

struct NewBudgetView: View {
    @ObservedObject var transactionStore: TransactionStore
    @ObservedObject var budgetStore: BudgetStore
    @State private var budgets: [Budget] = []
    @State private var showingAddBudget = false
    @State private var selectedBudget: Budget?
    @State private var showingAddItem = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Active Budgets")) {
                    ForEach(budgets) { budget in
                        BudgetRow(budget: budget, showingAddItem: $showingAddItem, selectedBudget: $selectedBudget)
                            .onTapGesture {
                                selectedBudget = budget
                            }
                    }
                }
                
                Section(header: Text("Debt Tracking")) {
                    ForEach(budgets.filter { $0.type == .debt }) { budget in
                        DebtRow(budget: budget, showingAddItem: $showingAddItem, selectedBudget: $selectedBudget)
                    }
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddBudget = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView(budgets: $budgets)
            }
            .sheet(item: $selectedBudget) { budget in
                if showingAddItem {
                    AddItemView(items: Binding(
                        get: { budget.items },
                        set: { newItems in
                            if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
                                var updatedBudget = budgets[index]
                                updatedBudget.items = newItems
                                budgets[index] = updatedBudget
                            }
                        }
                    ), onSave: { newItems in
                        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
                            var updatedBudget = budgets[index]
                            updatedBudget.items = newItems
                            budgets[index] = updatedBudget
                        }
                    })
                } else {
                    BudgetDetailView(budget: budget, showingAddItem: $showingAddItem, budgets: $budgets)
                }
            }
        }
    }
}

struct BudgetRow: View {
    let budget: Budget
    @Binding var showingAddItem: Bool
    @Binding var selectedBudget: Budget?
    
    var totalAmount: Double {
        budget.items.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.name)
                    .font(.headline)
                Spacer()
                Text(budget.period.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("R\(totalAmount, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    selectedBudget = budget
                    showingAddItem = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct DebtRow: View {
    let budget: Budget
    @Binding var showingAddItem: Bool
    @Binding var selectedBudget: Budget?
    
    var totalAmount: Double {
        budget.items.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.name)
                    .font(.headline)
                Spacer()
                Text(budget.period.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("R\(totalAmount, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.red)
                
                Spacer()
                
                Button(action: {
                    selectedBudget = budget
                    showingAddItem = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddBudgetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var budgets: [Budget]
    @State private var name = ""
    @State private var type: BudgetType = .spending
    @State private var period: BudgetPeriod = .monthly
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Budget Details")) {
                    TextField("Budget Name", text: $name)
                    
                    Picker("Type", selection: $type) {
                        ForEach(BudgetType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Picker("Period", selection: $period) {
                        ForEach(BudgetPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                }
            }
            .navigationTitle("New Budget")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createBudget()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func createBudget() {
        let budget = Budget(
            name: name,
            type: type,
            period: period,
            items: [],
            startDate: Date(),
            endDate: nil
        )
        
        budgets.append(budget)
        dismiss()
    }
}

struct BudgetDetailView: View {
    let budget: Budget
    @Binding var showingAddItem: Bool
    @Binding var budgets: [Budget]
    @State private var items: [BudgetItem]
    
    init(budget: Budget, showingAddItem: Binding<Bool>, budgets: Binding<[Budget]>) {
        self.budget = budget
        self._showingAddItem = showingAddItem
        self._budgets = budgets
        self._items = State(initialValue: budget.items)
    }
    
    var body: some View {
        List {
            Section(header: Text("Overview")) {
                HStack {
                    Text("Total Items")
                    Spacer()
                    Text("\(items.count)")
                }
                
                HStack {
                    Text("Total Amount")
                    Spacer()
                    Text("R\(items.reduce(0) { $0 + $1.amount }, specifier: "%.2f")")
                        .bold()
                }
            }
            
            Section(header: Text("Items")) {
                ForEach(items) { item in
                    ItemRow(item: item)
                }
                .onDelete(perform: deleteItems)
            }
        }
        .navigationTitle(budget.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddItem = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemView(items: $items, onSave: { newItems in
                updateBudgetItems(newItems)
            })
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        updateBudgetItems(items)
    }
    
    private func updateBudgetItems(_ newItems: [BudgetItem]) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            var updatedBudget = budgets[index]
            updatedBudget.items = newItems
            budgets[index] = updatedBudget
        }
    }
}

struct ItemRow: View {
    let item: BudgetItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.name)
                    .font(.headline)
                Spacer()
                Text("R\(item.amount, specifier: "%.2f")")
                    .foregroundColor(item.type == .income ? .green : .red)
            }
            
            HStack {
                Text(item.category)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(item.frequency.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var items: [BudgetItem]
    let onSave: ([BudgetItem]) -> Void
    @State private var name = ""
    @State private var amount = ""
    @State private var type: ItemType = .expense
    @State private var frequency: ItemFrequency = .fixed
    @State private var category = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item Name", text: $name)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Type", selection: $type) {
                        ForEach(ItemType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(ItemFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    
                    TextField("Category", text: $category)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("New Item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(name.isEmpty || amount.isEmpty || category.isEmpty)
                }
            }
        }
    }
    
    private func addItem() {
        guard let amountDouble = Double(amount) else { return }
        
        let item = BudgetItem(
            name: name,
            amount: amountDouble,
            type: type,
            frequency: frequency,
            category: category,
            date: date
        )
        
        var updatedItems = items
        updatedItems.append(item)
        onSave(updatedItems)
        dismiss()
    }
}

#Preview {
    NewBudgetView(transactionStore: TransactionStore(), budgetStore: BudgetStore())
} 