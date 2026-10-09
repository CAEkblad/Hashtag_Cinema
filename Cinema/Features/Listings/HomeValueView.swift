import SwiftUI
import UIKit

/// A sold comparable home the agent pulls from the MLS.
struct ValueComp: Identifiable, Hashable {
    var id = UUID()
    var address = ""
    var priceText = ""
    var sqftText = ""
    var beds = 3
    var baths: Double = 2

    var price: Double { Double(priceText.filter(\.isNumber)) ?? 0 }
    var sqft: Double { Double(sqftText.filter(\.isNumber)) ?? 0 }
    var pricePerSqft: Double? { sqft > 0 && price > 0 ? price / sqft : nil }
    var isComplete: Bool { !address.isEmpty && pricePerSqft != nil }
}

/// A one page "what your home is worth" report from 3 to 5 comps.
struct HomeValueView: View {
    @Environment(CinemaStore.self) private var store
    @State private var ownerName = ""
    @State private var address = ""
    @State private var sqftText = ""
    @State private var beds = 3
    @State private var baths: Double = 2
    @State private var comps: [ValueComp] = [ValueComp(), ValueComp(), ValueComp()]
    @State private var shareURL: URL?
    @State private var showShare = false

    private var subjectSqft: Double { Double(sqftText.filter(\.isNumber)) ?? 0 }
    private var usable: [ValueComp] { comps.filter(\.isComplete) }
    private var averagePPSF: Double? {
        guard !usable.isEmpty else { return nil }
        return usable.compactMap(\.pricePerSqft).reduce(0, +) / Double(usable.count)
    }
    private var estimate: (low: Double, mid: Double, high: Double)? {
        guard let averagePPSF, subjectSqft > 0 else { return nil }
        let mid = (averagePPSF * subjectSqft / 1_000).rounded() * 1_000
        let spread = usable.compactMap(\.pricePerSqft)
        let low = ((spread.min() ?? averagePPSF) * subjectSqft / 5_000).rounded() * 5_000
        let high = ((spread.max() ?? averagePPSF) * subjectSqft / 5_000).rounded() * 5_000
        return (min(low, mid * 0.97), mid, max(high, mid * 1.03))
    }

    private var canvas: HomeValueCanvas {
        HomeValueCanvas(ownerName: ownerName, address: address.isEmpty ? "Your home" : address, cityName: store.homeCity.name, sqft: subjectSqft, beds: beds, baths: baths, comps: usable, estimate: estimate, agentName: store.profile.name, brokerage: store.myMarketCenter?.name ?? store.profile.brokerage, kit: store.brandKit)
    }

    var body: some View {
        Form {
            Section {
                Text("Pull 3 to 5 recent sales near the home from the MLS. We'll average price per square foot and build a branded report.")
                    .font(.cinema(13))
                    .foregroundStyle(Theme.textSecondary)
            }
            .listRowBackground(Theme.surface)

            Section("The home") {
                TextField("Owner's name (optional)", text: $ownerName)
                TextField("Address", text: $address)
                    .textContentType(.fullStreetAddress)
                TextField("Living square feet", text: $sqftText)
                    .keyboardType(.numberPad)
                Stepper("\(beds) beds", value: $beds, in: 1...8)
                Stepper("\(SellerNetSheet.percent(baths).replacingOccurrences(of: "%", with: "")) baths", value: $baths, in: 1...8, step: 0.5)
            }
            .listRowBackground(Theme.surface)

            ForEach($comps) { $comp in
                Section("Sold comp") {
                    TextField("Address", text: $comp.address)
                    TextField("Sold price", text: $comp.priceText)
                        .keyboardType(.numberPad)
                    TextField("Square feet", text: $comp.sqftText)
                        .keyboardType(.numberPad)
                    Stepper("\(comp.beds) beds", value: $comp.beds, in: 1...8)
                    if let ppsf = comp.pricePerSqft {
                        Text("$\(Int(ppsf)) per sq ft")
                            .font(.cinema(12, weight: .semibold))
                            .foregroundStyle(Theme.red)
                    }
                }
                .listRowBackground(Theme.surface)
            }

            Section {
                if comps.count < 5 {
                    Button {
                        comps.append(ValueComp())
                    } label: {
                        Label("Add another comp", systemImage: "plus")
                    }
                }
                if let estimate {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estimated value")
                            .font(.cinema(12, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(money(estimate.low)) to \(money(estimate.high))")
                            .font(.cinema(22, weight: .heavy))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Most likely around \(money(estimate.mid)), from \(usable.count) comps")
                            .font(.cinema(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    Text("Add the home's square feet and at least one comp with a price and square feet.")
                        .font(.cinema(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Button {
                    makePDF()
                } label: {
                    Label("Share report PDF", systemImage: "square.and.arrow.up")
                }
                .disabled(estimate == nil)
            } footer: {
                Text("A broker price opinion for marketing, not an appraisal. Adjust for condition, upgrades, pool and water before you send it.")
            }
            .listRowBackground(Theme.surface)
        }
        .cinemaScreen()
        .navigationTitle("Home value report")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showShare) {
            if let shareURL {
                ActivityView(items: [shareURL])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    @MainActor
    private func makePDF() {
        let renderer = ImageRenderer(content: canvas)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Home-Value-Report.pdf")
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            context.beginPDFPage(nil)
            draw(context)
            context.endPDFPage()
            context.closePDF()
        }
        shareURL = url
        showShare = true
    }
}

struct HomeValueCanvas: View {
    let ownerName: String
    let address: String
    let cityName: String
    let sqft: Double
    let beds: Int
    let baths: Double
    let comps: [ValueComp]
    let estimate: (low: Double, mid: Double, high: Double)?
    let agentName: String
    let brokerage: String
    let kit: BrandKit

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(ownerName.isEmpty ? "HOME VALUE REPORT" : "PREPARED FOR \(ownerName.uppercased())")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.85))
                Text(address)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Text("\(beds) bed · \(SellerNetSheet.percent(baths).replacingOccurrences(of: "%", with: "")) bath · \(Int(sqft).formatted()) sq ft · \(Date().formatted(.dateTime.month(.wide).year()))")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(30)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(kit.accent)

            if let estimate {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ESTIMATED VALUE")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .kerning(1.5)
                        .foregroundStyle(Theme.textSecondary)
                    Text("\(money(estimate.low)) to \(money(estimate.high))")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text("Most likely around \(money(estimate.mid))")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(kit.accent)
                }
                .padding(.horizontal, 30)
                .padding(.top, 24)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("RECENT SALES NEARBY")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .kerning(1.5)
                    .foregroundStyle(Theme.textSecondary)
                HStack {
                    Text("Address").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Sold").frame(width: 90, alignment: .trailing)
                    Text("Sq ft").frame(width: 60, alignment: .trailing)
                    Text("$/sq ft").frame(width: 60, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                ForEach(comps) { comp in
                    HStack {
                        Text(comp.address).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                        Text(money(comp.price)).frame(width: 90, alignment: .trailing)
                        Text(Int(comp.sqft).formatted()).frame(width: 60, alignment: .trailing)
                        Text("$\(Int(comp.pricePerSqft ?? 0))").frame(width: 60, alignment: .trailing)
                    }
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    Divider()
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 24)

            Text("This is a broker price opinion based on recent nearby sales, not an appraisal. Condition, upgrades, a pool or water views can move the number. I'd love to see the home in person to give you an exact price.")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 30)
                .padding(.top, 18)

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                if let headshot = kit.headshotImage {
                    Image(uiImage: headshot)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(agentName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text([kit.phone, kit.website].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                        .font(.system(size: 12, design: .rounded))
                    Text(brokerage)
                        .font(.system(size: 11, design: .rounded))
                        .opacity(0.75)
                }
                .foregroundStyle(.white)
                Spacer()
                if let logo = kit.logoImage {
                    Image(uiImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 110, maxHeight: 44)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 16)
            .background(Theme.ink)
        }
        .frame(width: FlyerCanvas.size.width, height: FlyerCanvas.size.height)
        .background(Color.white)
    }
}
