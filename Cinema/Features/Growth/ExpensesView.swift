import SwiftUI

/// A business expense or a mileage trip, for tax time.
struct BusinessExpense: Identifiable, Hashable, Codable {
    enum Category: String, CaseIterable, Identifiable, Codable {
        case mileage, marketing, dues, signs, gifts, education, phone, other
        var id: String { rawValue }
        var title: String {
            switch self {
            case .mileage: return "Mileage"
            case .marketing: return "Marketing and shoots"
            case .dues: return "MLS and board dues"
            case .signs: return "Signs and lockboxes"
            case .gifts: return "Client gifts"
            case .education: return "Classes and licensing"
            case .phone: return "Phone and software"
            case .other: return "Other"
            }
        }
        var icon: String {
            switch self {
            case .mileage: return "car.fill"
            case .marketing: return "camera.fill"
            case .dues: return "building.columns.fill"
            case .signs: return "signpost.right.fill"
            case .gifts: return "gift.fill"
            case .education: return "graduationcap.fill"
            case .phone: return "iphone"
            case .other: return "tray.fill"
            }
        }
    }

    var id = UUID()
    var date: Date
    var category: Category
    /// Dollars for expenses, miles for mileage.
    var amount: Double
    var note: String
}

struct ExpensesView: View {
    @Environment(CinemaStore.self) private var store
    @State private var showAdd = false
    @State private var exportURL: URL?
    @State private var showExport = false

    private var year: Int { Calendar.current.component(.year, from: Date()) }
    private var thisYear: [BusinessExpense] {
        store.allExpenses.filter { Calendar.current.component(.year, from: $0.date) == year }
    }
    private var miles: Double { thisYear.filter { $0.category == .mileage }.reduce(0) { $0 + $1.amount } }
    private var spend: Double { thisYear.filter { $0.category != .mileage }.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mileage and expenses")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Log trips and business costs as you go. Finished #Cinema shoots are added for you. Export a spreadsheet for your accountant.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(spacing: 12) {
                    StatTile(value: "\(Int(miles).formatted())", label: "Miles in \(String(year))", icon: "car.fill")
                    StatTile(value: (miles * store.mileageRate).compactMoney, label: "At \(String(format: "$%.2f", store.mileageRate))/mi", icon: "road.lanes")
                    StatTile(value: spend.compactMoney, label: "Expenses", icon: "creditcard.fill")
                }

                HStack(spacing: 10) {
                    Button {
                        showAdd = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Button {
                        exportCSV()
                    } label: {
                        Label("Export CSV", systemImage: "tablecells")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(thisYear.isEmpty)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Stepper(String(format: "Mileage rate $%.3f a mile", store.mileageRate), value: Binding(get: { store.mileageRate }, set: { store.setMileageRate($0) }), in: 0.30...1.20, step: 0.005)
                        .font(.cinema(14))
                    Text("Set this to the current IRS standard mileage rate. Ask your tax pro what you can deduct.")
                        .font(.cinema(11))
                        .foregroundStyle(Theme.textTertiary)
                }
                .cardStyle()

                ForEach(BusinessExpense.Category.allCases) { category in
                    let items = thisYear.filter { $0.category == category }.sorted { $0.date > $1.date }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label(category.title, systemImage: category.icon)
                                    .font(.cinema(15, weight: .bold))
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text(category == .mileage ? "\(Int(items.reduce(0) { $0 + $1.amount })) mi" : items.reduce(0) { $0 + $1.amount }.compactMoney)
                                    .font(.cinema(13, weight: .semibold))
                                    .foregroundStyle(Theme.red)
                            }
                            ForEach(items) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.note.isEmpty ? category.title : item.note)
                                            .font(.cinema(13))
                                            .foregroundStyle(Theme.textPrimary)
                                            .lineLimit(1)
                                        Text(item.date.formatted(.dateTime.month(.abbreviated).day()))
                                            .font(.cinema(11))
                                            .foregroundStyle(Theme.textTertiary)
                                    }
                                    Spacer()
                                    Text(category == .mileage ? "\(String(format: "%.1f", item.amount)) mi" : item.amount.formatted(.currency(code: "USD")))
                                        .font(.cinema(13, weight: .semibold))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                .contextMenu {
                                    if store.expenses.contains(where: { $0.id == item.id }) {
                                        Button(role: .destructive) {
                                            store.deleteExpense(item.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .cardStyle()
                    }
                }
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Expenses")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) {
            AddExpenseView()
        }
        .sheet(isPresented: $showExport) {
            if let exportURL {
                ActivityView(items: [exportURL])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func exportCSV() {
        var rows = ["Date,Category,Amount,Unit,Deduction estimate,Note"]
        for item in thisYear.sorted(by: { $0.date < $1.date }) {
            let isMiles = item.category == .mileage
            let estimate = isMiles ? item.amount * store.mileageRate : item.amount
            let note = item.note.replacingOccurrences(of: "\"", with: "'")
            rows.append("\(item.date.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())),\(item.category.title),\(String(format: "%.2f", item.amount)),\(isMiles ? "miles" : "USD"),\(String(format: "%.2f", estimate)),\"\(note)\"")
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Cinema-Expenses-\(String(year)).csv")
        try? rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        exportURL = url
        showExport = true
    }
}

struct AddExpenseView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var presetMiles: Double? = nil
    var presetNote: String = ""

    @State private var category: BusinessExpense.Category = .mileage
    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $category) {
                    ForEach(BusinessExpense.Category.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                }
                TextField(category == .mileage ? "Miles" : "Amount in dollars", text: $amountText)
                    .keyboardType(.decimalPad)
                TextField(category == .mileage ? "Where to, like Showings with the Reeds" : "What for", text: $note)
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            .navigationTitle(category == .mileage ? "Log a trip" : "Add an expense")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                guard !didLoad else { return }
                didLoad = true
                if let presetMiles { amountText = String(format: "%.0f", presetMiles) }
                if !presetNote.isEmpty { note = presetNote }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addExpense(BusinessExpense(date: date, category: category, amount: Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0, note: note))
                        dismiss()
                    }
                    .disabled((Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0) <= 0)
                }
            }
        }
    }
}
