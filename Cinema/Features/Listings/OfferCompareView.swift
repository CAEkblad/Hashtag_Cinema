import SwiftUI

/// Side by side offers with the seller's net and how solid each one is,
/// so the seller sees more than the top line price.
struct OfferCompareView: View {
    @Environment(CinemaStore.self) private var store
    let listingID: UUID?
    @State private var offers: [OfferEntry] = []
    @State private var settings = OfferSettings()
    private var payoff: Double { settings.payoff }
    private var listingPercent: Double { settings.listingPercent }
    @State private var editing: OfferEntry?
    @State private var didLoad = false

    private var key: String { listingID?.uuidString ?? "general" }
    private var listing: Listing? { listingID.flatMap { store.listing($0) } }

    private func net(_ offer: OfferEntry) -> SellerNetSheet {
        SellerNetSheet(price: offer.price, payoff: payoff, listingPercent: listingPercent, buyerAgentPercent: offer.buyerAgentPercent, concessions: offer.sellerCredit, otherCosts: 0, miamiDade: listing?.cityID.contains("miami-dade") ?? false, sellerPaysTitle: true)
    }

    var body: some View {
        let bestNet = offers.max { net($0).net < net($1).net }?.id
        let strongest = offers.max { $0.strength < $1.strength }?.id
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Compare offers")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text((listing.map { "\($0.address). " } ?? "") + "The highest price isn't always the best offer. See what your seller nets and how likely each one is to close.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Mortgage payoff")
                            .font(.cinema(14, weight: .semibold))
                        Spacer()
                        TextField("0", value: $settings.payoff, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 140)
                    }
                    Stepper("Listing side \(SellerNetSheet.percent(listingPercent))", value: $settings.listingPercent, in: 0...6, step: 0.25)
                        .font(.cinema(14, weight: .semibold))
                }
                .foregroundStyle(Theme.textPrimary)
                .cardStyle()

                ForEach(offers) { offer in
                    offerCard(offer, isBestNet: offer.id == bestNet && offers.count > 1, isStrongest: offer.id == strongest && offers.count > 1)
                }

                Button {
                    editing = OfferEntry(buyerName: "Offer \(offers.count + 1)", price: Double(listing?.price ?? 450_000))
                } label: {
                    Label("Add an offer", systemImage: "plus")
                }
                .buttonStyle(offers.isEmpty ? AnyButtonStyle(PrimaryButtonStyle()) : AnyButtonStyle(SecondaryButtonStyle()))

                if offers.count > 1 {
                    ShareLink(item: summary) {
                        Label("Send the comparison to my seller", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                Text("Net is an estimate using Florida doc stamps and the owner's title policy at promulgated rates. Strength looks at financing, deposit, inspection period, appraisal gap, sale contingency and closing timeline.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Compare offers")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { offer in
            OfferEditView(offer: offer) { saved in
                if let index = offers.firstIndex(where: { $0.id == saved.id }) { offers[index] = saved } else { offers.append(saved) }
            } onDelete: { id in
                offers.removeAll { $0.id == id }
            }
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            offers = store.offers(for: key)
            settings = store.offerSettings(for: key)
        }
        .onChange(of: offers) { _, value in store.saveOffers(value, for: key) }
        .onChange(of: settings) { _, value in store.saveOfferSettings(value, for: key) }
    }

    private func offerCard(_ offer: OfferEntry, isBestNet: Bool, isStrongest: Bool) -> some View {
        let sheet = net(offer)
        return Button { editing = offer } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(offer.buyerName)
                        .font(.cinema(16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if isBestNet { Pill(text: "Best net", color: Theme.success.opacity(0.15), textColor: Theme.success) }
                    if isStrongest { Pill(text: "Strongest", color: Theme.redSoft, textColor: Theme.red) }
                }
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(offer.price.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                            .font(.cinema(20, weight: .bold))
                        Text("\(offer.financing.title) · close in \(offer.closingDays) days")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(sheet.net.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                            .font(.cinema(18, weight: .bold))
                            .foregroundStyle(Theme.success)
                        Text("Seller nets")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .foregroundStyle(Theme.textPrimary)
                HStack(spacing: 8) {
                    ProgressView(value: Double(offer.strength), total: 100)
                        .tint(offer.strength >= 70 ? Theme.success : offer.strength >= 50 ? Theme.red : Theme.textTertiary)
                    Text("\(offer.strength) strength")
                        .font(.cinema(12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                if !offer.strengthNotes.isEmpty {
                    Text(offer.strengthNotes.joined(separator: " · "))
                        .font(.cinema(12))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var summary: String {
        var lines = ["Here's how the offers compare\(listing.map { " on \($0.address)" } ?? ""):", ""]
        for offer in offers.sorted(by: { net($0).net > net($1).net }) {
            let sheet = net(offer)
            lines.append("\(offer.buyerName): \(offer.price.compactMoney) \(offer.financing.title.lowercased()), you net about \(sheet.net.compactMoney)")
            lines.append("  Closes in \(offer.closingDays) days, \(offer.inspectionDays == 0 ? "no inspection period" : "\(offer.inspectionDays) day inspection"), \(offer.escrowDeposit.compactMoney) deposit\(offer.sellerCredit > 0 ? ", \(offer.sellerCredit.compactMoney) credit to buyer" : "")")
            if !offer.strengthNotes.isEmpty { lines.append("  " + offer.strengthNotes.joined(separator: ", ")) }
            lines.append("")
        }
        lines.append("Let's talk through which one gets you to the closing table with the most in your pocket. \(store.profile.firstName)")
        return lines.joined(separator: "\n")
    }
}

struct OfferEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State var offer: OfferEntry
    let onSave: (OfferEntry) -> Void
    let onDelete: (UUID) -> Void

    private var money: FloatingPointFormatStyle<Double>.Currency { .currency(code: "USD").precision(.fractionLength(0)) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Offer") {
                    TextField("Buyer or offer name", text: $offer.buyerName)
                    moneyField("Price", value: $offer.price)
                    Picker("Financing", selection: $offer.financing) {
                        ForEach(OfferEntry.Financing.allCases) { Text($0.title).tag($0) }
                    }
                    if offer.financing != .cash {
                        Stepper("Down payment \(Int(offer.downPercent))%", value: $offer.downPercent, in: 0...100, step: 1)
                        moneyField("Appraisal gap covered", value: $offer.appraisalGap)
                    }
                }
                Section("Terms") {
                    moneyField("Escrow deposit", value: $offer.escrowDeposit)
                    moneyField("Seller credit to buyer", value: $offer.sellerCredit)
                    Stepper("Buyer's agent \(SellerNetSheet.percent(offer.buyerAgentPercent))", value: $offer.buyerAgentPercent, in: 0...6, step: 0.25)
                    Stepper("Inspection period \(offer.inspectionDays) days", value: $offer.inspectionDays, in: 0...30)
                    Stepper("Close in \(offer.closingDays) days", value: $offer.closingDays, in: 7...120)
                    Toggle("Needs to sell their home first", isOn: $offer.saleContingency)
                }
                Section("Notes") {
                    TextField("Escalation, rent back, anything else", text: $offer.notes, axis: .vertical)
                        .lineLimit(2...5)
                }
                Section {
                    Button("Delete this offer", role: .destructive) {
                        onDelete(offer.id)
                        dismiss()
                    }
                }
            }
            .navigationTitle(offer.buyerName.isEmpty ? "Offer" : offer.buyerName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(offer)
                        dismiss()
                    }
                    .disabled(offer.price <= 0)
                }
            }
        }
    }

    private func moneyField(_ title: String, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", value: value, format: money)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 140)
        }
    }
}
