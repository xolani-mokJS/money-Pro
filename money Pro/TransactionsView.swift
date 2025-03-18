import SwiftUI

struct TransactionsView: View {
    @ObservedObject var store: TransactionStore
    @ObservedObject var budgetStore: BudgetStore
    @State private var showingAddTransaction = false
    @State private var searchText = ""
    @State private var selectedTransactionType: TransactionTypeFilter = .all
    @State private var selectedDateFilter: DateFilter = .all
    @State private var showingFilterSheet = false
    @State private var selectedStartDate = Date()
    @State private var selectedEndDate = Date()
    @State private var showFilters = false
    @State private var activeFiltersCount: Int = 0
    
    enum TransactionTypeFilter: String, CaseIterable {
        case all = "All"
        case income = "Income"
        case expense = "Expense"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .income: return "arrow.down.circle.fill"
            case .expense: return "arrow.up.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .primary
            case .income: return .green
            case .expense: return .red
            }
        }
    }
    
    enum DateFilter: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case custom = "Custom Range"
    }
    
    private var activeFilters: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if selectedTransactionType != .all { count += 1 }
        if selectedDateFilter != .all { count += 1 }
        return count
    }
    
    var filteredTransactions: [Transaction] {
        var filtered = store.transactions
        
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch selectedTransactionType {
        case .income:
            filtered = filtered.filter { $0.type == .income }
        case .expense:
            filtered = filtered.filter { $0.type == .expense }
        case .all:
            break
        }
        
        switch selectedDateFilter {
        case .today:
            filtered = filtered.filter { Calendar.current.isDateInToday($0.date) }
        case .thisWeek:
            filtered = filtered.filter {
                Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear)
            }
        case .thisMonth:
            filtered = filtered.filter {
                Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
            }
        case .custom:
            filtered = filtered.filter {
                $0.date >= Calendar.current.startOfDay(for: selectedStartDate) &&
                $0.date <= Calendar.current.endOfDay(for: selectedEndDate)
            }
        case .all:
            break
        }
        
        return filtered.sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    // Enhanced Search Bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    // Filter Toggle
                    Button(action: { withAnimation { showFilters.toggle() }}) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .foregroundColor(activeFilters > 0 ? .blue : .gray)
                            Text(activeFilters > 0 ? "\(activeFilters) active filters" : "Add filters")
                                .foregroundColor(activeFilters > 0 ? .primary : .gray)
                            Spacer()
                            Image(systemName: showFilters ? "chevron.up" : "chevron.down")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    if showFilters {
                        VStack(spacing: 12) {
                            // Transaction Type Filter
                            HStack {
                                ForEach(TransactionTypeFilter.allCases, id: \.self) { type in
                                    FilterChip(
                                        title: type.rawValue,
                                        icon: type.icon,
                                        isSelected: selectedTransactionType == type,
                                        color: type.color
                                    ) {
                                        withAnimation {
                                            selectedTransactionType = type
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Date Filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(DateFilter.allCases, id: \.self) { filter in
                                        FilterChip(
                                            title: filter.rawValue,
                                            icon: "calendar",
                                            isSelected: selectedDateFilter == filter,
                                            color: .blue
                                        ) {
                                            withAnimation {
                                                selectedDateFilter = filter
                                                if filter == .custom {
                                                    showingFilterSheet = true
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.vertical)
                .background(Color(.systemGroupedBackground))
                
                // Transactions List
                if filteredTransactions.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "magnifyingglass",
                        description: Text("Try adjusting your filters or add a new transaction")
                    )
                } else {
                    List {
                        ForEach(filteredTransactions) { transaction in
                            TransactionRowView(transaction: transaction)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        if let index = store.transactions.firstIndex(where: { $0.id == transaction.id }) {
                                            deleteTransaction(at: IndexSet([index]))
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
                
                if activeFilters > 0 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Clear Filters") {
                            withAnimation {
                                searchText = ""
                                selectedTransactionType = .all
                                selectedDateFilter = .all
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView(store: store, budgetStore: budgetStore)
            }
            .sheet(isPresented: $showingFilterSheet) {
                DateFilterView(
                    startDate: $selectedStartDate,
                    endDate: $selectedEndDate,
                    isPresented: $showingFilterSheet
                )
            }
        }
    }
    
    private func deleteTransaction(at offsets: IndexSet) {
        store.transactions.remove(atOffsets: offsets)
        store.saveTransactions()
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search transactions", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { withAnimation { text = "" }}) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.2) : Color(.systemBackground))
            .foregroundColor(isSelected ? color : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct DateFilterView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

extension Calendar {
    func endOfDay(for date: Date) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return self.date(byAdding: components, to: self.startOfDay(for: date))!
    }
}

#Preview {
    TransactionsView(store: TransactionStore(), budgetStore: BudgetStore())
} 