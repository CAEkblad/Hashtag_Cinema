import SwiftUI

/// Every home under contract, with the next deadline up front.
struct DealsView: View {
    @Environment(CinemaStore.self) private var store
    @State private var showAdd = false

    private var open: [Deal] { store.deals.filter { !$0.isClosed }.sorted { $0.closingDate < $1.closingDate } }
    private var closed: [Deal] { store.deals.filter(\.isClosed) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Under contract")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Every deadline from contract to close, so nothing slips.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(spacing: 12) {
                    StatTile(value: "\(open.count)", label: "Pending", icon: "doc.text.fill")
                    StatTile(value: open.reduce(0) { $0 + $1.commission }.compactMoney, label: "Pending GCI", icon: "dollarsign.circle.fill")
                    StatTile(value: "\(open.flatMap(\.milestones).filter(\.isOverdue).count)", label: "Overdue", icon: "exclamationmark.triangle.fill")
                }

                Button {
                    showAdd = true
                } label: {
                    Label("Add a deal", systemImage: "plus")
                }
                .buttonStyle(PrimaryButtonStyle())

                ForEach(open) { deal in
                    NavigationLink(value: Route.deal(deal.id)) {
                        dealCard(deal)
                    }
                    .buttonStyle(.plain)
                }

                if !closed.isEmpty {
                    SectionHeader(title: "Closed")
                    ForEach(closed) { deal in
                        NavigationLink(value: Route.deal(deal.id)) {
                            IconRow(icon: "checkmark.seal.fill", title: deal.address, subtitle: "Closed \(deal.closingDate.formatted(.dateTime.month(.abbreviated).day())) · \(deal.priceLabel)")
                                .cardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Default dates follow the Florida Realtors/Florida Bar AS IS contract. Always check the dates in your signed contract.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Deals")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) {
            AddDealView()
        }
    }

    private func dealCard(_ deal: Deal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(deal.address)
                        .font(.cinema(16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(deal.clientName) · \(deal.side.title) · \(deal.priceLabel)")
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(deal.daysToClose >= 0 ? "\(deal.daysToClose)" : "Past")
                        .font(.cinema(20, weight: .heavy))
                        .foregroundStyle(Theme.red)
                    Text("days to close")
                        .font(.cinema(10))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            ProgressView(value: deal.progress)
                .tint(Theme.red)
            if let next = deal.nextMilestone {
                Label("\(next.title) · \(next.dueDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))", systemImage: next.isOverdue ? "exclamationmark.triangle.fill" : "clock.fill")
                    .font(.cinema(13, weight: .semibold))
                    .foregroundStyle(next.isOverdue ? Theme.red : Theme.textPrimary)
            }
        }
        .cardStyle()
    }
}

struct DealDetailView: View {
    @Environment(CinemaStore.self) private var store
    let dealID: UUID
    @State private var confirmClose = false

    var body: some View {
        if let deal = store.deal(dealID) {
            content(deal)
        } else {
            EmptyStateView(title: "Deal not found", message: "It may have been removed.", icon: "doc.text")
                .cinemaScreen()
        }
    }

    private func content(_ deal: Deal) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(deal.address)
                        .font(.cinema(20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(deal.clientName) · \(deal.side.title) · \(deal.priceLabel)")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Closing \(deal.closingDate.formatted(.dateTime.weekday(.wide).month(.wide).day())) · about \(deal.commission.compactMoney) at \(SellerNetSheet.percent(deal.commissionPercent))")
                        .font(.cinema(13, weight: .semibold))
                        .foregroundStyle(Theme.red)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Theme.surface)

            Section("Timeline") {
                ForEach(deal.milestones) { milestone in
                    HStack(alignment: .top, spacing: 12) {
                        Button {
                            store.toggleMilestone(milestone.id, dealID: deal.id)
                        } label: {
                            Image(systemName: milestone.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundStyle(milestone.isDone ? Theme.success : (milestone.isOverdue ? Theme.red : Theme.textTertiary))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(milestone.isDone ? "Mark not done" : "Mark done")
                        VStack(alignment: .leading, spacing: 3) {
                            Text(milestone.title)
                                .font(.cinema(15, weight: .semibold))
                                .foregroundStyle(milestone.isDone ? Theme.textSecondary : Theme.textPrimary)
                                .strikethrough(milestone.isDone)
                            Text(milestone.detail)
                                .font(.cinema(12))
                                .foregroundStyle(Theme.textSecondary)
                            DatePicker("Due", selection: Binding(get: { milestone.dueDate }, set: { store.setMilestoneDate($0, milestoneID: milestone.id, dealID: deal.id) }), displayedComponents: .date)
                                .font(.cinema(12))
                                .labelsHidden()
                        }
                        Spacer(minLength: 0)
                        if milestone.isOverdue {
                            Pill(text: "Overdue", color: Theme.redSoft, textColor: Theme.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowBackground(Theme.surface)

            Section {
                Toggle("Remind me the morning of each deadline", isOn: Binding(get: { deal.remindersOn }, set: { store.setDealReminders(deal.id, on: $0) }))
                    .tint(Theme.red)
                ShareLink(item: DealCopy.timeline(deal, agentName: store.profile.name)) {
                    Label("Send the timeline to \(deal.clientName.split(separator: " ").first.map(String.init) ?? "my client")", systemImage: "paperplane.fill")
                }
                if !deal.isClosed {
                    Button {
                        confirmClose = true
                    } label: {
                        Label("Mark as closed", systemImage: "checkmark.seal.fill")
                    }
                }
            }
            .listRowBackground(Theme.surface)
        }
        .cinemaScreen()
        .navigationTitle("Deal")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Mark \(deal.address) as closed?", isPresented: $confirmClose, titleVisibility: .visible) {
            Button("Closed! Add to past clients") { store.closeDeal(deal.id) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("We'll add \(deal.clientName) to Past clients with an anniversary reminder, and remind you to ask for a review.")
        }
    }
}

struct AddDealView: View {
    @Environment(CinemaStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var clientName = ""
    @State private var side: Testimonial.Side = .buyer
    @State private var priceText = ""
    @State private var effective = Date()
    @State private var closing = Calendar.current.date(byAdding: .day, value: 35, to: Date()) ?? Date()
    @State private var financed = true
    @State private var commission: Double = 3

    private var price: Int { Int(priceText.filter(\.isNumber)) ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                let contracted = store.listings.filter { $0.status == .underContract }
                if !contracted.isEmpty {
                    Section("Start from my listing") {
                        ForEach(contracted) { listing in
                            Button {
                                address = listing.address
                                priceText = "\(listing.price)"
                                side = .seller
                            } label: {
                                Label(listing.address, systemImage: "house.fill")
                            }
                        }
                    }
                }
                Section("Deal") {
                    TextField("Property address", text: $address)
                        .textContentType(.fullStreetAddress)
                    TextField("Client name", text: $clientName)
                        .textContentType(.name)
                    Picker("I represent the", selection: $side) {
                        ForEach(Testimonial.Side.allCases) { Text($0.title).tag($0) }
                    }
                    TextField("Contract price", text: $priceText)
                        .keyboardType(.numberPad)
                    Stepper("Commission \(SellerNetSheet.percent(commission))", value: $commission, in: 0...6, step: 0.25)
                }
                Section {
                    DatePicker("Effective date", selection: $effective, displayedComponents: .date)
                    DatePicker("Closing date", selection: $closing, in: effective..., displayedComponents: .date)
                    Toggle("Buyer is financing", isOn: $financed)
                        .tint(Theme.red)
                } header: {
                    Text("Dates")
                } footer: {
                    Text("We'll fill in Florida's default deadlines. You can change any date after.")
                }
            }
            .navigationTitle("Add a deal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addDeal(Deal(address: address.trimmingCharacters(in: .whitespaces), clientName: clientName.trimmingCharacters(in: .whitespaces), side: side, price: price, effectiveDate: effective, closingDate: closing, commissionPercent: commission, milestones: Deal.defaultMilestones(effective: effective, closing: closing, financed: financed)))
                        dismiss()
                    }
                    .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty || clientName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

extension Double {
    /// $12.4K style money for tight spaces.
    var compactMoney: String {
        if self >= 1_000_000 { return "$\(String(format: "%.1f", self / 1_000_000))M" }
        if self >= 1_000 { return "$\(String(format: "%.1f", self / 1_000))K" }
        return "$\(Int(self))"
    }
}
