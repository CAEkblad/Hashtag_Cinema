import SwiftUI
import UIKit

/// A branded "Moving to (city)" PDF for out of state buyers.
struct RelocationGuideView: View {
    @Environment(CinemaStore.self) private var store
    @State private var cityID: String?
    @State private var buyerName = ""
    @State private var showCityPicker = false
    @State private var shareFile: ShareFile?

    private var city: FloridaCity { FloridaMarkets.city(cityID) ?? store.homeCity }

    private var canvas: RelocationCanvas {
        RelocationCanvas(city: city, buyerName: buyerName, agentName: store.profile.name, brokerage: store.myMarketCenter?.name ?? store.profile.brokerage, kit: store.brandKit)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Moving to Florida guide")
                        .font(.cinema(26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Out of state buyers are some of the best leads. Send them a branded guide to the city and the Florida basics they won't know yet.")
                        .font(.cinema(14))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack {
                    Spacer()
                    canvas
                        .scaleEffect(300 / FlyerCanvas.size.width, anchor: .topLeading)
                        .frame(width: 300, height: 300 * FlyerCanvas.size.height / FlyerCanvas.size.width, alignment: .topLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 5)
                    Spacer()
                }

                Button {
                    showCityPicker = true
                } label: {
                    HStack {
                        Label(city.displayName, systemImage: "mappin.and.ellipse")
                            .font(.cinema(15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("Change")
                            .font(.cinema(14, weight: .semibold))
                            .foregroundStyle(Theme.red)
                    }
                    .inputStyle()
                }
                .buttonStyle(.plain)

                TextField("Buyer's name (optional)", text: $buyerName)
                    .textContentType(.name)
                    .inputStyle()

                Button {
                    makePDF()
                } label: {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("Florida basics are general information, not tax or legal advice. Buyers should confirm details with the county property appraiser and their insurance agent.")
                    .font(.cinema(11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Theme.gutter)
        }
        .cinemaScreen()
        .navigationTitle("Relocation guide")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showCityPicker) {
            CityPickerView(title: "Guide for which city?", selectedIDs: [city.id]) { picked in
                cityID = picked.id
            }
        }
        .sheet(item: $shareFile) { file in
            ActivityView(items: [file.url])
                .presentationDetents([.medium, .large])
        }
    }

    @MainActor
    private func makePDF() {
        let renderer = ImageRenderer(content: canvas)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Moving-to-\(city.name.replacingOccurrences(of: " ", with: "-")).pdf")
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            context.beginPDFPage(nil)
            draw(context)
            context.endPDFPage()
            context.closePDF()
        }
        shareFile = ShareFile(url: url)
    }
}

struct RelocationCanvas: View {
    let city: FloridaCity
    let buyerName: String
    let agentName: String
    let brokerage: String
    let kit: BrandKit

    static let basics: [(String, String)] = [
        ("dollarsign.circle.fill", "No state income tax. Florida has no personal income tax."),
        ("house.fill", "Homestead exemption. Owners who live in the home can save up to $50,000 off its assessed value. File with the county property appraiser by March 1."),
        ("chart.line.flattrend.xyaxis", "Save Our Homes. Once homesteaded, the assessed value can rise no more than 3% a year, or the inflation rate if lower."),
        ("wind", "Insurance. Ask for a wind mitigation inspection, and a 4 point inspection on older homes. Both can affect your premium."),
        ("water.waves", "Flood. Check the FEMA flood zone before you buy. Flood insurance is a separate policy."),
        ("car.fill", "New resident? Get a Florida driver license within 30 days.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(buyerName.isEmpty ? "YOUR GUIDE TO" : "PREPARED FOR \(buyerName.uppercased())")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.85))
                Text("Moving to \(city.name)")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("\(city.countyLine) · \(city.region.title)\(city.populationLabel.map { " · \($0)" } ?? "")")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(kit.accent)

            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    heading("Why people love it")
                    ForEach(Array(city.highlights.prefix(4).enumerated()), id: \.offset) { _, item in
                        bullet(item)
                    }
                    if !city.chipTraits.isEmpty {
                        Text(city.chipTraits.prefix(5).map(\.title).joined(separator: "  ·  "))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(kit.accent)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !city.neighborhoods.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        heading("Areas to know")
                        ForEach(Array(city.neighborhoods.prefix(6).enumerated()), id: \.offset) { _, item in
                            bullet(item)
                        }
                    }
                    .frame(width: 170, alignment: .leading)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 22)

            VStack(alignment: .leading, spacing: 10) {
                heading("Florida basics")
                ForEach(Array(Self.basics.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: item.0)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(kit.accent, in: Circle())
                        Text(item.1)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)

            Spacer(minLength: 0)

            Text("I help families move to \(city.name) every year. Call or text me and I'll set up a video tour of any home or neighborhood.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 28)
                .padding(.bottom, 14)

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
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(Theme.ink)
        }
        .frame(width: FlyerCanvas.size.width, height: FlyerCanvas.size.height)
        .background(Color.white)
    }

    private func heading(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .kerning(1.5)
            .foregroundStyle(Theme.ink)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(kit.accent)
                .frame(width: 5, height: 5)
                .padding(.top, 5)
            Text(text)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
